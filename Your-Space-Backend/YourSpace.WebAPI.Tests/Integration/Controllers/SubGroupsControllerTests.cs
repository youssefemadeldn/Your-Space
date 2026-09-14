using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using FluentAssertions;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.GroupService.Dtos;
using YourSpace.Services.Services.SubGroupService.Dtos;
using YourSpace.WebAPI.Tests.Common;

namespace YourSpace.WebAPI.Tests.Integration.Controllers;

// Covers only the new flat "all mine" endpoint added in row 8.14 (doc/local-first-sync-design.md
// §11) — the existing nested CRUD routes (create/get/update/delete under
// /groups/{id}/subgroups) have no integration coverage yet, same gap every Classification
// controller had before Row 8 (see CitiesControllerTests's own row 8.8 note); that gap is not
// this step's job to close.
public class SubGroupsControllerTests(TestWebApplicationFactory factory) : IClassFixture<TestWebApplicationFactory>
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web) { Converters = { new JsonStringEnumConverter() } };

    [Fact]
    public async Task GetAllMine_returns_subgroups_across_every_group_for_the_caller()
    {
        var client = await factory.CreateAuthenticatedClientAsync("subgroups.get-all-mine@example.com");

        var familyGroup = await DeserializeAsync<GroupDetailsDto>(
            await client.PostAsJsonAsync("/api/v1/Groups", new CreateGroupDto { Name = "Family" }));
        var friendsGroup = await DeserializeAsync<GroupDetailsDto>(
            await client.PostAsJsonAsync("/api/v1/Groups", new CreateGroupDto { Name = "Friends" }));

        var familySubGroupResponse = await client.PostAsJsonAsync(
            $"/api/v1/groups/{familyGroup.Data!.Id}/subgroups", new CreateSubGroupDto { Name = "Immediate Family" });
        familySubGroupResponse.StatusCode.Should().Be(HttpStatusCode.Created);
        var friendsSubGroupResponse = await client.PostAsJsonAsync(
            $"/api/v1/groups/{friendsGroup.Data!.Id}/subgroups", new CreateSubGroupDto { Name = "University Friends" });
        friendsSubGroupResponse.StatusCode.Should().Be(HttpStatusCode.Created);

        var response = await client.GetAsync("/api/v1/subgroups?pageIndex=1&pageSize=50");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var list = await DeserializeAsync<PaginatedResultDto<SubGroupProfileDto>>(response);
        list.Data!.Items.Should().Contain(s => s.Name == "Immediate Family" && s.GroupId == familyGroup.Data.Id);
        list.Data.Items.Should().Contain(s => s.Name == "University Friends" && s.GroupId == friendsGroup.Data.Id);
    }

    [Fact]
    public async Task GetAllMine_never_returns_another_user_s_subgroups()
    {
        var owner = await factory.CreateAuthenticatedClientAsync("subgroups.get-all-mine-owner@example.com");
        var group = await DeserializeAsync<GroupDetailsDto>(
            await owner.PostAsJsonAsync("/api/v1/Groups", new CreateGroupDto { Name = "Family" }));
        await owner.PostAsJsonAsync($"/api/v1/groups/{group.Data!.Id}/subgroups", new CreateSubGroupDto { Name = "Owner's SubGroup" });

        var intruder = await factory.CreateAuthenticatedClientAsync("subgroups.get-all-mine-intruder@example.com");
        var response = await intruder.GetAsync("/api/v1/subgroups?pageIndex=1&pageSize=50");

        var list = await DeserializeAsync<PaginatedResultDto<SubGroupProfileDto>>(response);
        list.Data!.Items.Should().NotContain(s => s.Name == "Owner's SubGroup");
    }

    [Fact]
    public async Task GetAllMine_rejects_unauthenticated_requests()
    {
        var client = factory.CreateClient();

        var response = await client.GetAsync("/api/v1/subgroups");

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    private static async Task<ServiceResult<T>> DeserializeAsync<T>(HttpResponseMessage response)
    {
        var result = await response.Content.ReadFromJsonAsync<ServiceResult<T>>(JsonOptions);
        return result!;
    }
}
