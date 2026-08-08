using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using FluentAssertions;
using YourSpace.Data.Enums;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.EventGuestService.Dtos;
using YourSpace.Services.Services.EventService.Dtos;
using YourSpace.Services.Services.GovernorateService.Dtos;
using YourSpace.Services.Services.GroupService.Dtos;
using YourSpace.Services.Services.PersonService.Dtos;
using YourSpace.WebAPI.Tests.Common;

namespace YourSpace.WebAPI.Tests.Integration.Controllers;

public class EventGuestsControllerTests(TestWebApplicationFactory factory) : IClassFixture<TestWebApplicationFactory>
{
    // Enums are serialized as strings on the wire (Program.cs registers JsonStringEnumConverter) —
    // the client-side deserializer needs the same converter or it'll try to parse "Invited" as an int.
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web) { Converters = { new JsonStringEnumConverter() } };

    [Fact]
    public async Task Add_whole_group_track_progress_and_transition_guest_status_end_to_end()
    {
        var client = await factory.CreateAuthenticatedClientAsync("event-guests.happy-path@example.com");

        var groupResponse = await client.PostAsJsonAsync("/api/v1/Groups", new CreateGroupDto { Name = "Village Friends" });
        var group = (await DeserializeAsync<GroupDetailsDto>(groupResponse)).Data!;

        var ahmedId = (await CreatePersonAsync(client, "Ahmed", group.Id)).Id;
        var saraId = (await CreatePersonAsync(client, "Sara", group.Id)).Id;

        var eventResponse = await client.PostAsJsonAsync("/api/v1/Events", new CreateEventDto { Name = "Brother's Wedding" });
        var eventId = (await DeserializeAsync<EventDetailsDto>(eventResponse)).Data!.Id;

        // Group-by-group workflow: add the whole group to the event's guest list in one action.
        var addGroupResponse = await client.PostAsync($"/api/v1/events/{eventId}/guests/by-group/{group.Id}", null);
        addGroupResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var addResult = await DeserializeAsync<BulkAddGuestsResultDto>(addGroupResponse);
        addResult.Data!.AddedCount.Should().Be(2);

        // Re-adding the same group is a safe no-op — both are already present.
        var reAddResponse = await client.PostAsync($"/api/v1/events/{eventId}/guests/by-group/{group.Id}", null);
        var reAddResult = await DeserializeAsync<BulkAddGuestsResultDto>(reAddResponse);
        reAddResult.Data!.AddedCount.Should().Be(0);
        reAddResult.Data.AlreadyPresentCount.Should().Be(2);

        var listResponse = await client.GetAsync($"/api/v1/events/{eventId}/guests");
        var list = await DeserializeAsync<PaginatedResultDto<EventGuestProfileDto>>(listResponse);
        list.Data!.Items.Should().HaveCount(2);
        var ahmedGuestId = list.Data.Items.Single(g => g.PersonId == ahmedId).Id;

        var inviteResponse = await client.PostAsJsonAsync($"/api/v1/events/{eventId}/guests/{ahmedGuestId}/invite", new MarkGuestInvitedDto { InviteMethod = InviteMethod.WhatsApp });
        inviteResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var invited = await DeserializeAsync<EventGuestDetailsDto>(inviteResponse);
        invited.Data!.Status.Should().Be(EventGuestStatus.Invited);
        invited.Data.InviteMethod.Should().Be(InviteMethod.WhatsApp);

        var progressResponse = await client.GetAsync($"/api/v1/events/{eventId}/guests/progress");
        var progress = await DeserializeAsync<EventGuestProgressSummaryDto>(progressResponse);
        progress.Data!.InvitedCount.Should().Be(1);
        progress.Data.NotInvitedCount.Should().Be(1);
        var groupProgress = progress.Data.Groups.Single(g => g.GroupId == group.Id);
        groupProgress.TotalPersonsInGroup.Should().Be(2);
        groupProgress.GuestsAddedCount.Should().Be(2);

        // No reciprocity history recorded yet — the suggestions list must come back empty, not error.
        var suggestionsResponse = await client.GetAsync($"/api/v1/events/{eventId}/guests/reciprocity-suggestions");
        suggestionsResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var suggestions = await DeserializeAsync<PaginatedResultDto<PersonProfileDto>>(suggestionsResponse);
        suggestions.Data!.Items.Should().BeEmpty();

        var saraGuestId = list.Data.Items.Single(g => g.PersonId == saraId).Id;
        var removeResponse = await client.DeleteAsync($"/api/v1/events/{eventId}/guests/{saraGuestId}");
        removeResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        var listAfterRemoveResponse = await client.GetAsync($"/api/v1/events/{eventId}/guests");
        var listAfterRemove = await DeserializeAsync<PaginatedResultDto<EventGuestProfileDto>>(listAfterRemoveResponse);
        listAfterRemove.Data!.Items.Should().ContainSingle();
    }

    [Fact]
    public async Task Returns_not_found_when_a_different_user_requests_another_owners_event_guests()
    {
        var owner = await factory.CreateAuthenticatedClientAsync("event-guests.owner@example.com");
        var groupResponse = await owner.PostAsJsonAsync("/api/v1/Groups", new CreateGroupDto { Name = "Owner's Group" });
        var group = (await DeserializeAsync<GroupDetailsDto>(groupResponse)).Data!;
        await CreatePersonAsync(owner, "Ahmed", group.Id);
        var eventResponse = await owner.PostAsJsonAsync("/api/v1/Events", new CreateEventDto { Name = "Owner's Wedding" });
        var eventId = (await DeserializeAsync<EventDetailsDto>(eventResponse)).Data!.Id;
        await owner.PostAsync($"/api/v1/events/{eventId}/guests/by-group/{group.Id}", null);
        var listResponseForOwner = await owner.GetAsync($"/api/v1/events/{eventId}/guests");
        var guestId = (await DeserializeAsync<PaginatedResultDto<EventGuestProfileDto>>(listResponseForOwner)).Data!.Items.Single().Id;

        var intruder = await factory.CreateAuthenticatedClientAsync("event-guests.intruder@example.com");

        var listResponse = await intruder.GetAsync($"/api/v1/events/{eventId}/guests");
        listResponse.StatusCode.Should().Be(HttpStatusCode.NotFound, "the event itself must not resolve for a caller who doesn't own it");

        var guestResponse = await intruder.GetAsync($"/api/v1/events/{eventId}/guests/{guestId}");
        guestResponse.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Rejects_unauthenticated_requests()
    {
        var client = factory.CreateClient();

        var response = await client.GetAsync("/api/v1/events/1/guests");

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    private static async Task<PersonDetailsDto> CreatePersonAsync(HttpClient client, string name, int groupId)
    {
        var governorateId = await CreateGovernorateAsync(client, $"{name}'s Governorate");
        var response = await client.PostAsJsonAsync("/api/v1/Persons",
            new CreatePersonDto { Name = name, GroupId = groupId, GovernorateId = governorateId, Gender = Gender.Male });
        return (await DeserializeAsync<PersonDetailsDto>(response)).Data!;
    }

    private static async Task<int> CreateGovernorateAsync(HttpClient client, string name)
    {
        var response = await client.PostAsJsonAsync("/api/v1/Governorates", new CreateGovernorateDto { Name = name });
        return (await DeserializeAsync<GovernorateDetailsDto>(response)).Data!.Id;
    }

    private static async Task<ServiceResult<T>> DeserializeAsync<T>(HttpResponseMessage response)
    {
        var result = await response.Content.ReadFromJsonAsync<ServiceResult<T>>(JsonOptions);
        return result!;
    }
}
