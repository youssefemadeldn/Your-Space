using System.Linq;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using YourSpace.Data.Contexts;
using YourSpace.Data.Entities;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.GovernorateService.Dtos;
using YourSpace.WebAPI.Helpers;
using YourSpace.WebAPI.Tests.Common;

namespace YourSpace.WebAPI.Tests.Integration.Seeders;

// ReferenceDataSeeder runs from Program.cs on every boot (not gated behind IsDevelopment()), so
// the shared TestWebApplicationFactory has already run it by the time any test here executes.
public class ReferenceDataSeederTests(TestWebApplicationFactory factory) : IClassFixture<TestWebApplicationFactory>
{
    private static readonly JsonSerializerOptions JsonOptions =
        new(JsonSerializerDefaults.Web) { Converters = { new JsonStringEnumConverter() } };

    [Fact]
    public void Seeds_all_27_global_governorates_on_startup()
    {
        using var scope = factory.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<YourSpaceDbContext>();

        var globals = context.Governorates.Where(g => g.OwnerUserId == null).ToList();

        globals.Should().HaveCount(EgyptianGovernorates.All.Count);
        globals.Should().OnlyContain(g => g.IsLocked && g.DeletedAt == null);
        globals.Should().Contain(g => g.Name == "Cairo" && g.NameAr == "القاهرة");
        globals.Should().Contain(g => g.Name == "South Sinai" && g.NameAr == "جنوب سيناء");
        globals.Select(g => g.Name).Should().BeEquivalentTo(EgyptianGovernorates.All.Select(g => g.En));
    }

    [Fact]
    public async Task Running_again_inserts_nothing_and_does_not_throw()
    {
        using var scope = factory.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<YourSpaceDbContext>();
        var before = await context.Governorates.CountAsync(g => g.OwnerUserId == null);

        await ReferenceDataSeeder.SeedAsync(scope.ServiceProvider, NullLogger.Instance);

        var after = await context.Governorates.CountAsync(g => g.OwnerUserId == null);
        after.Should().Be(before);
    }

    [Fact]
    public async Task Re_seeds_only_the_rows_that_are_missing()
    {
        // Own factory — this test deletes a global row, which would otherwise perturb the
        // class-shared fixture other tests rely on.
        await using var isolatedFactory = new TestWebApplicationFactory();
        isolatedFactory.CreateClient(); // force host build → Program.cs startup seeders run

        using var scope = isolatedFactory.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<YourSpaceDbContext>();

        var luxor = await context.Governorates.SingleAsync(g => g.OwnerUserId == null && g.Name == "Luxor");
        context.Governorates.Remove(luxor);
        await context.SaveChangesAsync();
        context.ChangeTracker.Clear();

        await ReferenceDataSeeder.SeedAsync(scope.ServiceProvider, NullLogger.Instance);

        var globals = context.Governorates.Where(g => g.OwnerUserId == null).ToList();
        globals.Should().HaveCount(EgyptianGovernorates.All.Count);
        globals.Should().ContainSingle(g => g.Name == "Luxor" && g.NameAr == "الأقصر");
    }

    [Fact]
    public async Task Global_governorates_are_visible_through_the_api_to_any_authenticated_user()
    {
        var client = await factory.CreateAuthenticatedClientAsync("governorates.seed-visibility@example.com");

        var response = await client.GetAsync("/api/v1/Governorates?pageIndex=1&pageSize=50");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var list = await DeserializeAsync<PaginatedResultDto<GovernorateProfileDto>>(response);
        list.Data!.Items.Should().Contain(g => g.Name == "Cairo" && g.IsLocked);
        list.Data.Items.Count(g => g.IsLocked).Should().Be(EgyptianGovernorates.All.Count);
    }

    private static async Task<ServiceResult<T>> DeserializeAsync<T>(HttpResponseMessage response)
        => (await response.Content.ReadFromJsonAsync<ServiceResult<T>>(JsonOptions))!;
}
