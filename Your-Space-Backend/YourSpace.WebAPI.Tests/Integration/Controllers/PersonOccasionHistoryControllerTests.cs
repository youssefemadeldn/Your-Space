using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using FluentAssertions;
using YourSpace.Data.Enums;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.GovernorateService.Dtos;
using YourSpace.Services.Services.GroupService.Dtos;
using YourSpace.Services.Services.PersonOccasionHistoryService.Dtos;
using YourSpace.Services.Services.PersonService.Dtos;
using YourSpace.WebAPI.Tests.Common;

namespace YourSpace.WebAPI.Tests.Integration.Controllers;

public class PersonOccasionHistoryControllerTests(TestWebApplicationFactory factory) : IClassFixture<TestWebApplicationFactory>
{
    // Enums are serialized as strings on the wire (Program.cs registers JsonStringEnumConverter) —
    // the client-side deserializer needs the same converter or it'll try to parse "WhatsApp" as an int.
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web) { Converters = { new JsonStringEnumConverter() } };

    [Fact]
    public async Task Create_get_update_and_delete_occasion_history_happy_path_succeeds()
    {
        var client = await factory.CreateAuthenticatedClientAsync("occasion-history.happy-path@example.com");
        var personId = await CreatePersonAsync(client, "Ahmed");

        var createResponse = await client.PostAsJsonAsync($"/api/v1/persons/{personId}/occasion-history", new CreatePersonOccasionHistoryDto
        {
            InvitedMe = true,
            InviteMethod = InviteMethod.WhatsApp,
            OccasionName = "His Wedding"
        });
        createResponse.StatusCode.Should().Be(HttpStatusCode.Created);
        var created = await DeserializeAsync<PersonOccasionHistoryDetailsDto>(createResponse);
        var historyId = created.Data!.Id;

        // Person details must now reflect the reciprocity flag set by this history entry.
        var personResponse = await client.GetAsync($"/api/v1/Persons/{personId}");
        var person = await DeserializeAsync<PersonDetailsDto>(personResponse);
        person.Data!.HasReciprocityHistory.Should().BeTrue();

        var updateResponse = await client.PutAsJsonAsync($"/api/v1/persons/{personId}/occasion-history", new UpdatePersonOccasionHistoryDto
        {
            Id = historyId,
            InvitedMe = false
        });
        updateResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var updated = await DeserializeAsync<PersonOccasionHistoryDetailsDto>(updateResponse);
        updated.Data!.InviteMethod.Should().BeNull("InvitedMe=false must clear any recorded method server-side");

        var deleteResponse = await client.DeleteAsync($"/api/v1/persons/{personId}/occasion-history/{historyId}");
        deleteResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        var getAfterDeleteResponse = await client.GetAsync($"/api/v1/persons/{personId}/occasion-history/{historyId}");
        getAfterDeleteResponse.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Returns_not_found_when_a_different_user_requests_another_owners_persons_history()
    {
        var owner = await factory.CreateAuthenticatedClientAsync("occasion-history.owner@example.com");
        var personId = await CreatePersonAsync(owner, "Ahmed");
        var createResponse = await owner.PostAsJsonAsync($"/api/v1/persons/{personId}/occasion-history", new CreatePersonOccasionHistoryDto { InvitedMe = false });
        var historyId = (await DeserializeAsync<PersonOccasionHistoryDetailsDto>(createResponse)).Data!.Id;

        var intruder = await factory.CreateAuthenticatedClientAsync("occasion-history.intruder@example.com");

        var listResponse = await intruder.GetAsync($"/api/v1/persons/{personId}/occasion-history");
        listResponse.StatusCode.Should().Be(HttpStatusCode.NotFound, "the person itself must not resolve for a caller who doesn't own it");

        var detailsResponse = await intruder.GetAsync($"/api/v1/persons/{personId}/occasion-history/{historyId}");
        detailsResponse.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Rejects_unauthenticated_requests()
    {
        var client = factory.CreateClient();

        var response = await client.GetAsync("/api/v1/persons/1/occasion-history");

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    private static async Task<int> CreatePersonAsync(HttpClient client, string name)
    {
        var groupResponse = await client.PostAsJsonAsync("/api/v1/Groups", new CreateGroupDto { Name = $"{name}'s Group" });
        var group = await DeserializeAsync<GroupDetailsDto>(groupResponse);

        var governorateResponse = await client.PostAsJsonAsync("/api/v1/Governorates", new CreateGovernorateDto { Name = $"{name}'s Governorate" });
        var governorate = await DeserializeAsync<GovernorateDetailsDto>(governorateResponse);

        var personResponse = await client.PostAsJsonAsync("/api/v1/Persons",
            new CreatePersonDto { Name = name, GroupId = group.Data!.Id, GovernorateId = governorate.Data!.Id, Gender = Gender.Male });
        var person = await DeserializeAsync<PersonDetailsDto>(personResponse);
        return person.Data!.Id;
    }

    private static async Task<ServiceResult<T>> DeserializeAsync<T>(HttpResponseMessage response)
    {
        var result = await response.Content.ReadFromJsonAsync<ServiceResult<T>>(JsonOptions);
        return result!;
    }
}
