using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using FluentAssertions;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.CityService.Dtos;
using YourSpace.Services.Services.GovernorateService.Dtos;
using YourSpace.Services.Services.NeighborhoodService.Dtos;
using YourSpace.WebAPI.Tests.Common;

namespace YourSpace.WebAPI.Tests.Integration.Controllers;

// Covers the new flat "all mine" endpoint added in row 8.20 (doc/local-first-sync-design.md §11)
// — the existing nested CRUD routes (create/get/update/delete under
// /cities/{cityId}/neighborhoods) still have no dedicated integration coverage of their own,
// same gap every Classification controller had before Row 8 (see CitiesControllerTests's own
// row 8.8 note); that gap is not this step's job to close — the CRUD calls below exist only to
// set up state for the flat-endpoint assertions.
public class NeighborhoodsControllerTests(TestWebApplicationFactory factory) : IClassFixture<TestWebApplicationFactory>
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web) { Converters = { new JsonStringEnumConverter() } };

    private static async Task<int> CreateOwnCityAsync(HttpClient client, string cityName)
    {
        var governorateId = (await DeserializeAsync<PaginatedResultDto<GovernorateProfileDto>>(
            await client.GetAsync("/api/v1/Governorates?pageIndex=1&pageSize=50")))
            .Data!.Items.Single(g => g.Name == "Cairo").Id;
        var city = await DeserializeAsync<CityDetailsDto>(
            await client.PostAsJsonAsync($"/api/v1/governorates/{governorateId}/cities", new CreateCityDto { Name = cityName }));
        return city.Data!.Id;
    }

    [Fact]
    public async Task GetAllMine_returns_neighborhoods_across_every_city_for_the_caller()
    {
        var client = await factory.CreateAuthenticatedClientAsync("neighborhoods.get-all-mine@example.com");
        var cityAId = await CreateOwnCityAsync(client, "Maadi");
        var cityBId = await CreateOwnCityAsync(client, "Dokki");

        var zamalekResponse = await client.PostAsJsonAsync($"/api/v1/cities/{cityAId}/neighborhoods", new CreateNeighborhoodDto { Name = "Zamalek" });
        zamalekResponse.StatusCode.Should().Be(HttpStatusCode.Created);
        var sarayatResponse = await client.PostAsJsonAsync($"/api/v1/cities/{cityBId}/neighborhoods", new CreateNeighborhoodDto { Name = "Sarayat" });
        sarayatResponse.StatusCode.Should().Be(HttpStatusCode.Created);

        var response = await client.GetAsync("/api/v1/neighborhoods?pageIndex=1&pageSize=50");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var list = await DeserializeAsync<PaginatedResultDto<NeighborhoodProfileDto>>(response);
        list.Data!.Items.Should().Contain(n => n.Name == "Zamalek" && n.CityId == cityAId);
        list.Data.Items.Should().Contain(n => n.Name == "Sarayat" && n.CityId == cityBId);
    }

    [Fact]
    public async Task GetAllMine_never_returns_another_user_s_neighborhoods()
    {
        var owner = await factory.CreateAuthenticatedClientAsync("neighborhoods.get-all-mine-owner@example.com");
        var cityId = await CreateOwnCityAsync(owner, "Owner's City");
        await owner.PostAsJsonAsync($"/api/v1/cities/{cityId}/neighborhoods", new CreateNeighborhoodDto { Name = "Owner's Neighborhood" });

        var intruder = await factory.CreateAuthenticatedClientAsync("neighborhoods.get-all-mine-intruder@example.com");
        var response = await intruder.GetAsync("/api/v1/neighborhoods?pageIndex=1&pageSize=50");

        var list = await DeserializeAsync<PaginatedResultDto<NeighborhoodProfileDto>>(response);
        list.Data!.Items.Should().NotContain(n => n.Name == "Owner's Neighborhood");
    }

    [Fact]
    public async Task GetAllMine_rejects_unauthenticated_requests()
    {
        var client = factory.CreateClient();

        var response = await client.GetAsync("/api/v1/neighborhoods");

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    private static async Task<ServiceResult<T>> DeserializeAsync<T>(HttpResponseMessage response)
    {
        var result = await response.Content.ReadFromJsonAsync<ServiceResult<T>>(JsonOptions);
        return result!;
    }
}
