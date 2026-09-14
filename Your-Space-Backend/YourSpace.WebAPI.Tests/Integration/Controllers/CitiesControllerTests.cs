using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using FluentAssertions;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.CityService.Dtos;
using YourSpace.Services.Services.GovernorateService.Dtos;
using YourSpace.WebAPI.Tests.Common;

namespace YourSpace.WebAPI.Tests.Integration.Controllers;

// Covers the new flat endpoints added in rows 8.8 ("all mine") and 8.11 (delta-sync "changes")
// (doc/local-first-sync-design.md §11) — the existing nested CRUD routes (create/get/update/
// delete under /governorates/{id}/cities) still have no dedicated integration coverage of their
// own, same gap every Classification controller had before Row 8 (see
// GovernoratesControllerTests's own row 8.5 note); that gap is not this step's job to close —
// the CRUD calls below exist only to set up state for the flat-endpoint assertions.
public class CitiesControllerTests(TestWebApplicationFactory factory) : IClassFixture<TestWebApplicationFactory>
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web) { Converters = { new JsonStringEnumConverter() } };

    [Fact]
    public async Task GetAllMine_returns_cities_across_every_governorate_for_the_caller()
    {
        var client = await factory.CreateAuthenticatedClientAsync("cities.get-all-mine@example.com");

        var cairoId = (await DeserializeAsync<PaginatedResultDto<GovernorateProfileDto>>(
            await client.GetAsync("/api/v1/Governorates?pageIndex=1&pageSize=50")))
            .Data!.Items.Single(g => g.Name == "Cairo").Id;
        var gizaId = (await DeserializeAsync<PaginatedResultDto<GovernorateProfileDto>>(
            await client.GetAsync("/api/v1/Governorates?pageIndex=1&pageSize=50")))
            .Data!.Items.Single(g => g.Name == "Giza").Id;

        var cairoCityResponse = await client.PostAsJsonAsync($"/api/v1/governorates/{cairoId}/cities", new CreateCityDto { Name = "Maadi" });
        cairoCityResponse.StatusCode.Should().Be(HttpStatusCode.Created);
        var gizaCityResponse = await client.PostAsJsonAsync($"/api/v1/governorates/{gizaId}/cities", new CreateCityDto { Name = "Dokki" });
        gizaCityResponse.StatusCode.Should().Be(HttpStatusCode.Created);

        var response = await client.GetAsync("/api/v1/cities?pageIndex=1&pageSize=50");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var list = await DeserializeAsync<PaginatedResultDto<CityProfileDto>>(response);
        list.Data!.Items.Should().Contain(c => c.Name == "Maadi" && c.GovernorateId == cairoId);
        list.Data.Items.Should().Contain(c => c.Name == "Dokki" && c.GovernorateId == gizaId);
    }

    [Fact]
    public async Task GetAllMine_never_returns_another_user_s_cities()
    {
        var owner = await factory.CreateAuthenticatedClientAsync("cities.get-all-mine-owner@example.com");
        var governorateId = (await DeserializeAsync<PaginatedResultDto<GovernorateProfileDto>>(
            await owner.GetAsync("/api/v1/Governorates?pageIndex=1&pageSize=50")))
            .Data!.Items.Single(g => g.Name == "Cairo").Id;
        await owner.PostAsJsonAsync($"/api/v1/governorates/{governorateId}/cities", new CreateCityDto { Name = "Owner's City" });

        var intruder = await factory.CreateAuthenticatedClientAsync("cities.get-all-mine-intruder@example.com");
        var response = await intruder.GetAsync("/api/v1/cities?pageIndex=1&pageSize=50");

        var list = await DeserializeAsync<PaginatedResultDto<CityProfileDto>>(response);
        list.Data!.Items.Should().NotContain(c => c.Name == "Owner's City");
    }

    [Fact]
    public async Task GetAllMine_rejects_unauthenticated_requests()
    {
        var client = factory.CreateClient();

        var response = await client.GetAsync("/api/v1/cities");

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Changes_reflects_create_update_and_soft_delete_via_an_increasing_syncversion_cursor()
    {
        var client = await factory.CreateAuthenticatedClientAsync("cities.changes@example.com");
        var governorateId = (await DeserializeAsync<PaginatedResultDto<GovernorateProfileDto>>(
            await client.GetAsync("/api/v1/Governorates?pageIndex=1&pageSize=50")))
            .Data!.Items.Single(g => g.Name == "Cairo").Id;

        var created = await DeserializeAsync<CityDetailsDto>(
            await client.PostAsJsonAsync($"/api/v1/governorates/{governorateId}/cities", new CreateCityDto { Name = "Maadi" }));
        var cityId = created.Data!.Id;
        var createdVersion = created.Data.SyncVersion;

        var beforeCreate = await DeserializeAsync<CityChangesDto>(
            await client.GetAsync($"/api/v1/cities/changes?since={createdVersion - 1}"));
        beforeCreate.Data!.Upserts.Should().Contain(c => c.Id == cityId);
        beforeCreate.Data.TombstoneIds.Should().NotContain(cityId);

        var atCreatedVersion = await DeserializeAsync<CityChangesDto>(
            await client.GetAsync($"/api/v1/cities/changes?since={createdVersion}"));
        atCreatedVersion.Data!.Upserts.Should().NotContain(c => c.Id == cityId, "already seen up to this cursor");

        var updated = await DeserializeAsync<CityDetailsDto>(
            await client.PutAsJsonAsync($"/api/v1/governorates/{governorateId}/cities/{cityId}", new UpdateCityDto { Name = "Maadi (Updated)" }));
        updated.Data!.SyncVersion.Should().BeGreaterThan(createdVersion, "an update must bump the cursor, not just create");

        var afterUpdate = await DeserializeAsync<CityChangesDto>(
            await client.GetAsync($"/api/v1/cities/changes?since={createdVersion}"));
        afterUpdate.Data!.Upserts.Should().Contain(c => c.Id == cityId && c.Name == "Maadi (Updated)");

        await client.DeleteAsync($"/api/v1/governorates/{governorateId}/cities/{cityId}");

        var afterDelete = await DeserializeAsync<CityChangesDto>(
            await client.GetAsync($"/api/v1/cities/changes?since={updated.Data.SyncVersion}"));
        afterDelete.Data!.TombstoneIds.Should().Contain(cityId);
        afterDelete.Data.Upserts.Should().NotContain(c => c.Id == cityId);
    }

    [Fact]
    public async Task Changes_never_returns_another_user_s_cities()
    {
        var owner = await factory.CreateAuthenticatedClientAsync("cities.changes-owner@example.com");
        var governorateId = (await DeserializeAsync<PaginatedResultDto<GovernorateProfileDto>>(
            await owner.GetAsync("/api/v1/Governorates?pageIndex=1&pageSize=50")))
            .Data!.Items.Single(g => g.Name == "Cairo").Id;
        await owner.PostAsJsonAsync($"/api/v1/governorates/{governorateId}/cities", new CreateCityDto { Name = "Owner's City" });

        var intruder = await factory.CreateAuthenticatedClientAsync("cities.changes-intruder@example.com");
        var response = await DeserializeAsync<CityChangesDto>(await intruder.GetAsync("/api/v1/cities/changes?since=0&pageSize=500"));

        response.Data!.Upserts.Should().NotContain(c => c.Name == "Owner's City");
    }

    [Fact]
    public async Task Changes_rejects_a_negative_since_cursor()
    {
        var client = await factory.CreateAuthenticatedClientAsync("cities.changes-invalid@example.com");

        var response = await client.GetAsync("/api/v1/cities/changes?since=-1");

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task Changes_rejects_unauthenticated_requests()
    {
        var client = factory.CreateClient();

        var response = await client.GetAsync("/api/v1/cities/changes");

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    private static async Task<ServiceResult<T>> DeserializeAsync<T>(HttpResponseMessage response)
    {
        var result = await response.Content.ReadFromJsonAsync<ServiceResult<T>>(JsonOptions);
        return result!;
    }
}
