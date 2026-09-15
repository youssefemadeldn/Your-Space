using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using FluentAssertions;
using YourSpace.Data.Enums;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.GovernorateService.Dtos;
using YourSpace.Services.Services.GroupService.Dtos;
using YourSpace.Services.Services.PersonRelationshipService.Dtos;
using YourSpace.Services.Services.PersonService.Dtos;
using YourSpace.WebAPI.Tests.Common;

namespace YourSpace.WebAPI.Tests.Integration.Controllers;

// Row 9.13/9.16's new flat endpoint — deliberately scoped to just this endpoint, matching
// CitiesControllerTests'/EventGuestsControllerTests' own doc comment precedent: the pre-existing
// nested CRUD routes have no controller-level coverage yet, a known gap, not this step's job.
public class PersonRelationshipsControllerTests(TestWebApplicationFactory factory) : IClassFixture<TestWebApplicationFactory>
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web) { Converters = { new JsonStringEnumConverter() } };

    [Fact]
    public async Task GetAllMine_returns_both_the_forward_and_auto_derived_inverse_row()
    {
        var client = await factory.CreateAuthenticatedClientAsync("person-relationships.flat@example.com");

        var governorateId = (await DeserializeAsync<GovernorateDetailsDto>(
            await client.PostAsJsonAsync("/api/v1/Governorates", new CreateGovernorateDto { Name = "Cairo" }))).Data!.Id;
        var groupId = (await DeserializeAsync<GroupDetailsDto>(
            await client.PostAsJsonAsync("/api/v1/Groups", new CreateGroupDto { Name = "Family" }))).Data!.Id;
        var subjectId = (await DeserializeAsync<PersonDetailsDto>(await client.PostAsJsonAsync("/api/v1/Persons",
            new CreatePersonDto { Name = "Youssef", GroupId = groupId, GovernorateId = governorateId, Gender = Gender.Male }))).Data!.Id;
        var relatedId = (await DeserializeAsync<PersonDetailsDto>(await client.PostAsJsonAsync("/api/v1/Persons",
            new CreatePersonDto { Name = "Ahmed", GroupId = groupId, GovernorateId = governorateId, Gender = Gender.Male }))).Data!.Id;

        var created = await DeserializeAsync<PersonRelationshipDetailsDto>(
            await client.PostAsJsonAsync($"/api/v1/persons/{subjectId}/relationships",
                new CreatePersonRelationshipDto { RelatedPersonId = relatedId, RelationType = RelationType.Father }));
        created.Data!.InverseId.Should().NotBe(created.Data.Id);

        var response = await client.GetAsync("/api/v1/person-relationships");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var relationships = (await DeserializeAsync<List<PersonRelationshipProfileDto>>(response)).Data!;
        relationships.Should().HaveCount(2);
        relationships.Should().Contain(r => r.Id == created.Data.Id && r.PersonId == subjectId);
        relationships.Should().Contain(r => r.Id == created.Data.InverseId && r.PersonId == relatedId);
    }

    [Fact]
    public async Task GetAllMine_rejects_unauthenticated_requests()
    {
        var client = factory.CreateClient();

        var response = await client.GetAsync("/api/v1/person-relationships");

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    private static async Task<ServiceResult<T>> DeserializeAsync<T>(HttpResponseMessage response)
    {
        var result = await response.Content.ReadFromJsonAsync<ServiceResult<T>>(JsonOptions);
        return result!;
    }
}
