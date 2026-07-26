using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.GroupService.Dtos;
using YourSpace.Services.Services.PersonService.Dtos;
using YourSpace.WebAPI.Tests.Common;

namespace YourSpace.WebAPI.Tests.Integration.Controllers;

public class PersonsControllerTests(TestWebApplicationFactory factory) : IClassFixture<TestWebApplicationFactory>
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    [Fact]
    public async Task Create_get_update_and_delete_person_happy_path_succeeds()
    {
        var client = await factory.CreateAuthenticatedClientAsync("persons.happy-path@example.com");

        var groupResponse = await client.PostAsJsonAsync("/api/v1/Groups", new CreateGroupDto { Name = "Relatives" });
        var group = await DeserializeAsync<GroupDetailsDto>(groupResponse);

        var createResponse = await client.PostAsJsonAsync("/api/v1/Persons", new CreatePersonDto
        {
            Name = "Ahmed",
            PhoneNumber = "+201234567890",
            GroupId = group.Data!.Id
        });
        createResponse.StatusCode.Should().Be(HttpStatusCode.Created);
        var created = await DeserializeAsync<PersonDetailsDto>(createResponse);
        created.Data!.GroupName.Should().Be("Relatives");
        created.Data.HasReciprocityHistory.Should().BeFalse();
        var personId = created.Data.Id;

        var updateResponse = await client.PutAsJsonAsync("/api/v1/Persons", new UpdatePersonDto { Id = personId, Name = "Ahmed Updated" });
        updateResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        var deleteResponse = await client.DeleteAsync($"/api/v1/Persons/{personId}");
        deleteResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        var getAfterDeleteResponse = await client.GetAsync($"/api/v1/Persons/{personId}");
        getAfterDeleteResponse.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Returns_not_found_when_creating_a_person_in_another_users_group()
    {
        var ownerClient = await factory.CreateAuthenticatedClientAsync("persons.owner@example.com");
        var groupResponse = await ownerClient.PostAsJsonAsync("/api/v1/Groups", new CreateGroupDto { Name = "Owner's Group" });
        var group = await DeserializeAsync<GroupDetailsDto>(groupResponse);

        var otherClient = await factory.CreateAuthenticatedClientAsync("persons.intruder@example.com");
        var response = await otherClient.PostAsJsonAsync("/api/v1/Persons", new CreatePersonDto { Name = "Ahmed", GroupId = group.Data!.Id });

        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Rejects_unauthenticated_requests()
    {
        var client = factory.CreateClient();

        var response = await client.GetAsync("/api/v1/Persons");

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    private static async Task<ServiceResult<T>> DeserializeAsync<T>(HttpResponseMessage response)
    {
        var result = await response.Content.ReadFromJsonAsync<ServiceResult<T>>(JsonOptions);
        return result!;
    }
}
