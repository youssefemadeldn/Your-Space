using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.GroupService.Dtos;
using YourSpace.WebAPI.Tests.Common;

namespace YourSpace.WebAPI.Tests.Integration.Controllers;

public class GroupsControllerTests(TestWebApplicationFactory factory) : IClassFixture<TestWebApplicationFactory>
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    [Fact]
    public async Task Create_get_update_and_delete_group_happy_path_succeeds()
    {
        var client = await factory.CreateAuthenticatedClientAsync("groups.happy-path@example.com");

        var createResponse = await client.PostAsJsonAsync("/api/v1/Groups", new CreateGroupDto { Name = "Village Friends" });
        createResponse.StatusCode.Should().Be(HttpStatusCode.Created);
        var created = await DeserializeAsync<GroupDetailsDto>(createResponse);
        var groupId = created.Data!.Id;

        var getResponse = await client.GetAsync($"/api/v1/Groups/{groupId}");
        getResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        var updateResponse = await client.PutAsJsonAsync("/api/v1/Groups", new UpdateGroupDto { Id = groupId, Name = "Village Friends (Updated)" });
        updateResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var updated = await DeserializeAsync<GroupDetailsDto>(updateResponse);
        updated.Data!.Name.Should().Be("Village Friends (Updated)");

        var listResponse = await client.GetAsync("/api/v1/Groups");
        var list = await DeserializeAsync<PaginatedResultDto<GroupProfileDto>>(listResponse);
        list.Data!.Items.Should().Contain(g => g.Id == groupId);

        var deleteResponse = await client.DeleteAsync($"/api/v1/Groups/{groupId}");
        deleteResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        var getAfterDeleteResponse = await client.GetAsync($"/api/v1/Groups/{groupId}");
        getAfterDeleteResponse.StatusCode.Should().Be(HttpStatusCode.NotFound, "the group is soft-deleted and must no longer resolve");
    }

    [Fact]
    public async Task Get_all_reports_the_true_total_when_more_rows_exist_than_one_page()
    {
        // Regression guard for the exact bug the plan called out: CountWithSpecAsync and
        // ListAllWithSpecAsync must never share one paginated spec instance, or the count silently
        // caps to page size. Runs against the real SQLite provider (unlike
        // GroupService_GetAllAsyncTests, which mocks the repository and can't detect a
        // spec-instance-reuse regression at all — the mock returns whatever it's told regardless
        // of the spec's Skip/Take).
        var client = await factory.CreateAuthenticatedClientAsync("groups.pagination@example.com");

        for (var i = 1; i <= 15; i++)
        {
            var createResponse = await client.PostAsJsonAsync("/api/v1/Groups", new CreateGroupDto { Name = $"Group {i:D2}" });
            createResponse.StatusCode.Should().Be(HttpStatusCode.Created);
        }

        var listResponse = await client.GetAsync("/api/v1/Groups?pageIndex=1&pageSize=10");
        listResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var list = await DeserializeAsync<PaginatedResultDto<GroupProfileDto>>(listResponse);

        list.Data!.TotalItems.Should().Be(15, "the count must reflect every matching row, not just what fits on one page");
        list.Data.Items.Should().HaveCount(10);
        list.Data.TotalPages.Should().Be(2);
    }

    [Fact]
    public async Task Returns_not_found_when_a_different_user_requests_the_group()
    {
        var owner = await factory.CreateAuthenticatedClientAsync("groups.owner@example.com");
        var createResponse = await owner.PostAsJsonAsync("/api/v1/Groups", new CreateGroupDto { Name = "Owner's Group" });
        var groupId = (await DeserializeAsync<GroupDetailsDto>(createResponse)).Data!.Id;

        var intruder = await factory.CreateAuthenticatedClientAsync("groups.intruder@example.com");
        var response = await intruder.GetAsync($"/api/v1/Groups/{groupId}");

        response.StatusCode.Should().Be(HttpStatusCode.NotFound, "another user's group must be invisible, not merely forbidden");
    }

    [Fact]
    public async Task Rejects_unauthenticated_requests()
    {
        var client = factory.CreateClient();

        var response = await client.GetAsync("/api/v1/Groups");

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    private static async Task<ServiceResult<T>> DeserializeAsync<T>(HttpResponseMessage response)
    {
        var result = await response.Content.ReadFromJsonAsync<ServiceResult<T>>(JsonOptions);
        return result!;
    }
}
