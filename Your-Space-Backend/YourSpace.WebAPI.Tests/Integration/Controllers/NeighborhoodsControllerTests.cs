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

// Covers the new flat endpoints added in rows 8.20 ("all mine") and 8.23 (delta-sync "changes")
// (doc/local-first-sync-design.md §11) — the existing nested CRUD routes (create/get/update/
// delete under /cities/{cityId}/neighborhoods) still have no dedicated integration coverage of
// their own, same gap every Classification controller had before Row 8 (see
// CitiesControllerTests's own row 8.8/8.11 notes); that gap is not this step's job to close —
// the CRUD calls below exist only to set up state for the flat-endpoint assertions.
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

    [Fact]
    public async Task Changes_reflects_create_update_and_soft_delete_via_an_increasing_syncversion_cursor()
    {
        var client = await factory.CreateAuthenticatedClientAsync("neighborhoods.changes@example.com");
        var cityId = await CreateOwnCityAsync(client, "Maadi");

        var created = await DeserializeAsync<NeighborhoodDetailsDto>(
            await client.PostAsJsonAsync($"/api/v1/cities/{cityId}/neighborhoods", new CreateNeighborhoodDto { Name = "Zamalek" }));
        var neighborhoodId = created.Data!.Id;
        var createdVersion = created.Data.SyncVersion;

        var beforeCreate = await DeserializeAsync<NeighborhoodChangesDto>(
            await client.GetAsync($"/api/v1/neighborhoods/changes?since={createdVersion - 1}"));
        beforeCreate.Data!.Upserts.Should().Contain(n => n.Id == neighborhoodId);
        beforeCreate.Data.TombstoneIds.Should().NotContain(neighborhoodId);

        var atCreatedVersion = await DeserializeAsync<NeighborhoodChangesDto>(
            await client.GetAsync($"/api/v1/neighborhoods/changes?since={createdVersion}"));
        atCreatedVersion.Data!.Upserts.Should().NotContain(n => n.Id == neighborhoodId, "already seen up to this cursor");

        var updated = await DeserializeAsync<NeighborhoodDetailsDto>(
            await client.PutAsJsonAsync($"/api/v1/cities/{cityId}/neighborhoods/{neighborhoodId}", new UpdateNeighborhoodDto { Name = "Zamalek (Updated)" }));
        updated.Data!.SyncVersion.Should().BeGreaterThan(createdVersion, "an update must bump the cursor, not just create");

        var afterUpdate = await DeserializeAsync<NeighborhoodChangesDto>(
            await client.GetAsync($"/api/v1/neighborhoods/changes?since={createdVersion}"));
        afterUpdate.Data!.Upserts.Should().Contain(n => n.Id == neighborhoodId && n.Name == "Zamalek (Updated)");

        await client.DeleteAsync($"/api/v1/cities/{cityId}/neighborhoods/{neighborhoodId}");

        var afterDelete = await DeserializeAsync<NeighborhoodChangesDto>(
            await client.GetAsync($"/api/v1/neighborhoods/changes?since={updated.Data.SyncVersion}"));
        afterDelete.Data!.TombstoneIds.Should().Contain(neighborhoodId);
        afterDelete.Data.Upserts.Should().NotContain(n => n.Id == neighborhoodId);
    }

    [Fact]
    public async Task Changes_never_returns_another_user_s_neighborhoods()
    {
        var owner = await factory.CreateAuthenticatedClientAsync("neighborhoods.changes-owner@example.com");
        var cityId = await CreateOwnCityAsync(owner, "Owner's City");
        await owner.PostAsJsonAsync($"/api/v1/cities/{cityId}/neighborhoods", new CreateNeighborhoodDto { Name = "Owner's Neighborhood" });

        var intruder = await factory.CreateAuthenticatedClientAsync("neighborhoods.changes-intruder@example.com");
        var response = await DeserializeAsync<NeighborhoodChangesDto>(
            await intruder.GetAsync("/api/v1/neighborhoods/changes?since=0&pageSize=500"));

        response.Data!.Upserts.Should().NotContain(n => n.Name == "Owner's Neighborhood");
    }

    [Fact]
    public async Task Changes_rejects_a_negative_since_cursor()
    {
        var client = await factory.CreateAuthenticatedClientAsync("neighborhoods.changes-invalid@example.com");

        var response = await client.GetAsync("/api/v1/neighborhoods/changes?since=-1");

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task Changes_rejects_unauthenticated_requests()
    {
        var client = factory.CreateClient();

        var response = await client.GetAsync("/api/v1/neighborhoods/changes");

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    private static async Task<ServiceResult<T>> DeserializeAsync<T>(HttpResponseMessage response)
    {
        var result = await response.Content.ReadFromJsonAsync<ServiceResult<T>>(JsonOptions);
        return result!;
    }
}
