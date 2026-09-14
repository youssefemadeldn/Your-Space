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

// Covers the new flat endpoints added in rows 8.14 ("all mine") and 8.17 (delta-sync "changes")
// (doc/local-first-sync-design.md §11) — the existing nested CRUD routes (create/get/update/
// delete under /groups/{id}/subgroups) still have no dedicated integration coverage of their
// own, same gap every Classification controller had before Row 8 (see CitiesControllerTests's
// own row 8.8/8.11 notes); that gap is not this step's job to close — the CRUD calls below exist
// only to set up state for the flat-endpoint assertions.
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

    [Fact]
    public async Task Changes_reflects_create_update_and_soft_delete_via_an_increasing_syncversion_cursor()
    {
        var client = await factory.CreateAuthenticatedClientAsync("subgroups.changes@example.com");
        var group = await DeserializeAsync<GroupDetailsDto>(
            await client.PostAsJsonAsync("/api/v1/Groups", new CreateGroupDto { Name = "Family" }));

        var created = await DeserializeAsync<SubGroupDetailsDto>(
            await client.PostAsJsonAsync($"/api/v1/groups/{group.Data!.Id}/subgroups", new CreateSubGroupDto { Name = "Immediate Family" }));
        var subGroupId = created.Data!.Id;
        var createdVersion = created.Data.SyncVersion;

        var beforeCreate = await DeserializeAsync<SubGroupChangesDto>(
            await client.GetAsync($"/api/v1/subgroups/changes?since={createdVersion - 1}"));
        beforeCreate.Data!.Upserts.Should().Contain(s => s.Id == subGroupId);
        beforeCreate.Data.TombstoneIds.Should().NotContain(subGroupId);

        var atCreatedVersion = await DeserializeAsync<SubGroupChangesDto>(
            await client.GetAsync($"/api/v1/subgroups/changes?since={createdVersion}"));
        atCreatedVersion.Data!.Upserts.Should().NotContain(s => s.Id == subGroupId, "already seen up to this cursor");

        var updated = await DeserializeAsync<SubGroupDetailsDto>(
            await client.PutAsJsonAsync($"/api/v1/groups/{group.Data.Id}/subgroups/{subGroupId}", new UpdateSubGroupDto { Name = "Immediate Family (Updated)" }));
        updated.Data!.SyncVersion.Should().BeGreaterThan(createdVersion, "an update must bump the cursor, not just create");

        var afterUpdate = await DeserializeAsync<SubGroupChangesDto>(
            await client.GetAsync($"/api/v1/subgroups/changes?since={createdVersion}"));
        afterUpdate.Data!.Upserts.Should().Contain(s => s.Id == subGroupId && s.Name == "Immediate Family (Updated)");

        await client.DeleteAsync($"/api/v1/groups/{group.Data.Id}/subgroups/{subGroupId}");

        var afterDelete = await DeserializeAsync<SubGroupChangesDto>(
            await client.GetAsync($"/api/v1/subgroups/changes?since={updated.Data.SyncVersion}"));
        afterDelete.Data!.TombstoneIds.Should().Contain(subGroupId);
        afterDelete.Data.Upserts.Should().NotContain(s => s.Id == subGroupId);
    }

    [Fact]
    public async Task Changes_never_returns_another_user_s_subgroups()
    {
        var owner = await factory.CreateAuthenticatedClientAsync("subgroups.changes-owner@example.com");
        var group = await DeserializeAsync<GroupDetailsDto>(
            await owner.PostAsJsonAsync("/api/v1/Groups", new CreateGroupDto { Name = "Family" }));
        await owner.PostAsJsonAsync($"/api/v1/groups/{group.Data!.Id}/subgroups", new CreateSubGroupDto { Name = "Owner's SubGroup" });

        var intruder = await factory.CreateAuthenticatedClientAsync("subgroups.changes-intruder@example.com");
        var response = await DeserializeAsync<SubGroupChangesDto>(await intruder.GetAsync("/api/v1/subgroups/changes?since=0&pageSize=500"));

        response.Data!.Upserts.Should().NotContain(s => s.Name == "Owner's SubGroup");
    }

    [Fact]
    public async Task Changes_rejects_a_negative_since_cursor()
    {
        var client = await factory.CreateAuthenticatedClientAsync("subgroups.changes-invalid@example.com");

        var response = await client.GetAsync("/api/v1/subgroups/changes?since=-1");

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task Changes_rejects_unauthenticated_requests()
    {
        var client = factory.CreateClient();

        var response = await client.GetAsync("/api/v1/subgroups/changes");

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    private static async Task<ServiceResult<T>> DeserializeAsync<T>(HttpResponseMessage response)
    {
        var result = await response.Content.ReadFromJsonAsync<ServiceResult<T>>(JsonOptions);
        return result!;
    }
}
