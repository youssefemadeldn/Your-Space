using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using FluentAssertions;
using YourSpace.Data.Enums;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.GovernorateService.Dtos;
using YourSpace.Services.Services.GroupService.Dtos;
using YourSpace.Services.Services.PersonService.Dtos;
using YourSpace.WebAPI.Tests.Common;

namespace YourSpace.WebAPI.Tests.Integration.Controllers;

public class PersonsControllerTests(TestWebApplicationFactory factory) : IClassFixture<TestWebApplicationFactory>
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web) { Converters = { new JsonStringEnumConverter() } };

    [Fact]
    public async Task Create_get_update_and_delete_person_happy_path_succeeds()
    {
        var client = await factory.CreateAuthenticatedClientAsync("persons.happy-path@example.com");

        var groupResponse = await client.PostAsJsonAsync("/api/v1/Groups", new CreateGroupDto { Name = "Relatives" });
        var group = await DeserializeAsync<GroupDetailsDto>(groupResponse);

        var governorateResponse = await client.PostAsJsonAsync("/api/v1/Governorates", new CreateGovernorateDto { Name = "Cairo" });
        var governorate = await DeserializeAsync<GovernorateDetailsDto>(governorateResponse);

        var createResponse = await client.PostAsJsonAsync("/api/v1/Persons", new CreatePersonDto
        {
            Name = "Ahmed",
            PhoneNumber = "+201234567890",
            GroupId = group.Data!.Id,
            GovernorateId = governorate.Data!.Id,
            Gender = Gender.Male
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
        // GovernorateId=1 is never actually resolved — the GroupId check runs first and fails
        // before Governorate validation is ever reached, so a placeholder value is fine here.
        var response = await otherClient.PostAsJsonAsync("/api/v1/Persons",
            new CreatePersonDto { Name = "Ahmed", GroupId = group.Data!.Id, GovernorateId = 1, Gender = Gender.Male });

        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Rejects_unauthenticated_requests()
    {
        var client = factory.CreateClient();

        var response = await client.GetAsync("/api/v1/Persons");

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Changes_reflects_create_update_and_soft_delete_via_an_increasing_syncversion_cursor()
    {
        var client = await factory.CreateAuthenticatedClientAsync("persons.changes@example.com");
        var group = await DeserializeAsync<GroupDetailsDto>(
            await client.PostAsJsonAsync("/api/v1/Groups", new CreateGroupDto { Name = "Relatives" }));
        var governorate = await DeserializeAsync<GovernorateDetailsDto>(
            await client.PostAsJsonAsync("/api/v1/Governorates", new CreateGovernorateDto { Name = "Cairo" }));

        var created = await DeserializeAsync<PersonDetailsDto>(await client.PostAsJsonAsync("/api/v1/Persons", new CreatePersonDto
        {
            Name = "Nadia",
            GroupId = group.Data!.Id,
            GovernorateId = governorate.Data!.Id,
            Gender = Gender.Female
        }));
        var personId = created.Data!.Id;
        var createdVersion = created.Data.SyncVersion;

        var beforeCreate = await DeserializeAsync<PersonChangesDto>(
            await client.GetAsync($"/api/v1/Persons/changes?since={createdVersion - 1}"));
        beforeCreate.Data!.Upserts.Should().Contain(p => p.Id == personId);
        beforeCreate.Data.TombstoneIds.Should().NotContain(personId);

        var atCreatedVersion = await DeserializeAsync<PersonChangesDto>(
            await client.GetAsync($"/api/v1/Persons/changes?since={createdVersion}"));
        atCreatedVersion.Data!.Upserts.Should().NotContain(p => p.Id == personId, "already seen up to this cursor");

        var updated = await DeserializeAsync<PersonDetailsDto>(
            await client.PutAsJsonAsync("/api/v1/Persons", new UpdatePersonDto { Id = personId, Name = "Nadia Updated" }));
        updated.Data!.SyncVersion.Should().BeGreaterThan(createdVersion, "an update must bump the cursor, not just create");

        var afterUpdate = await DeserializeAsync<PersonChangesDto>(
            await client.GetAsync($"/api/v1/Persons/changes?since={createdVersion}"));
        afterUpdate.Data!.Upserts.Should().Contain(p => p.Id == personId && p.Name == "Nadia Updated");

        await client.DeleteAsync($"/api/v1/Persons/{personId}");

        var afterDelete = await DeserializeAsync<PersonChangesDto>(
            await client.GetAsync($"/api/v1/Persons/changes?since={updated.Data.SyncVersion}"));
        afterDelete.Data!.TombstoneIds.Should().Contain(personId);
        afterDelete.Data.Upserts.Should().NotContain(p => p.Id == personId);
    }

    [Fact]
    public async Task Changes_rejects_a_negative_since_cursor()
    {
        var client = await factory.CreateAuthenticatedClientAsync("persons.changes-invalid@example.com");

        var response = await client.GetAsync("/api/v1/Persons/changes?since=-1");

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task Changes_rejects_unauthenticated_requests()
    {
        var client = factory.CreateClient();

        var response = await client.GetAsync("/api/v1/Persons/changes");

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    private static async Task<ServiceResult<T>> DeserializeAsync<T>(HttpResponseMessage response)
    {
        var result = await response.Content.ReadFromJsonAsync<ServiceResult<T>>(JsonOptions);
        return result!;
    }
}
