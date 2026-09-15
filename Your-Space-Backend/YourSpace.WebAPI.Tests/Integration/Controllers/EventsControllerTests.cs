using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using FluentAssertions;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.EventService.Dtos;
using YourSpace.WebAPI.Tests.Common;

namespace YourSpace.WebAPI.Tests.Integration.Controllers;

public class EventsControllerTests(TestWebApplicationFactory factory) : IClassFixture<TestWebApplicationFactory>
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web) { Converters = { new JsonStringEnumConverter() } };

    [Fact]
    public async Task Create_get_update_and_delete_event_happy_path_succeeds()
    {
        var client = await factory.CreateAuthenticatedClientAsync("events.happy-path@example.com");

        var createResponse = await client.PostAsJsonAsync("/api/v1/Events", new CreateEventDto { Name = "Brother's Wedding" });
        createResponse.StatusCode.Should().Be(HttpStatusCode.Created);
        var created = await DeserializeAsync<EventDetailsDto>(createResponse);
        created.Data!.TotalGuestCount.Should().Be(0);
        var eventId = created.Data.Id;

        var updateResponse = await client.PutAsJsonAsync("/api/v1/Events", new UpdateEventDto { Id = eventId, Name = "Brother's Wedding (Updated)" });
        updateResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        var deleteResponse = await client.DeleteAsync($"/api/v1/Events/{eventId}");
        deleteResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        var getAfterDeleteResponse = await client.GetAsync($"/api/v1/Events/{eventId}");
        getAfterDeleteResponse.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Returns_not_found_when_a_different_user_requests_the_event()
    {
        var owner = await factory.CreateAuthenticatedClientAsync("events.owner@example.com");
        var createResponse = await owner.PostAsJsonAsync("/api/v1/Events", new CreateEventDto { Name = "Owner's Wedding" });
        var eventId = (await DeserializeAsync<EventDetailsDto>(createResponse)).Data!.Id;

        var intruder = await factory.CreateAuthenticatedClientAsync("events.intruder@example.com");
        var response = await intruder.GetAsync($"/api/v1/Events/{eventId}");

        response.StatusCode.Should().Be(HttpStatusCode.NotFound, "another user's event must be invisible, not merely forbidden");
    }

    [Fact]
    public async Task Rejects_unauthenticated_requests()
    {
        var client = factory.CreateClient();

        var response = await client.GetAsync("/api/v1/Events");

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Changes_reflects_create_update_and_soft_delete_via_an_increasing_syncversion_cursor()
    {
        var client = await factory.CreateAuthenticatedClientAsync("events.changes@example.com");

        var created = await DeserializeAsync<EventDetailsDto>(
            await client.PostAsJsonAsync("/api/v1/Events", new CreateEventDto { Name = "Village Gathering" }));
        var eventId = created.Data!.Id;
        var createdVersion = created.Data.SyncVersion;

        var beforeCreate = await DeserializeAsync<EventChangesDto>(
            await client.GetAsync($"/api/v1/Events/changes?since={createdVersion - 1}"));
        beforeCreate.Data!.Upserts.Should().Contain(e => e.Id == eventId);
        beforeCreate.Data.TombstoneIds.Should().NotContain(eventId);

        var atCreatedVersion = await DeserializeAsync<EventChangesDto>(
            await client.GetAsync($"/api/v1/Events/changes?since={createdVersion}"));
        atCreatedVersion.Data!.Upserts.Should().NotContain(e => e.Id == eventId, "already seen up to this cursor");

        var updated = await DeserializeAsync<EventDetailsDto>(
            await client.PutAsJsonAsync("/api/v1/Events", new UpdateEventDto { Id = eventId, Name = "Village Gathering (Updated)" }));
        updated.Data!.SyncVersion.Should().BeGreaterThan(createdVersion, "an update must bump the cursor, not just create");

        var afterUpdate = await DeserializeAsync<EventChangesDto>(
            await client.GetAsync($"/api/v1/Events/changes?since={createdVersion}"));
        afterUpdate.Data!.Upserts.Should().Contain(e => e.Id == eventId && e.Name == "Village Gathering (Updated)");

        await client.DeleteAsync($"/api/v1/Events/{eventId}");

        var afterDelete = await DeserializeAsync<EventChangesDto>(
            await client.GetAsync($"/api/v1/Events/changes?since={updated.Data.SyncVersion}"));
        afterDelete.Data!.TombstoneIds.Should().Contain(eventId);
        afterDelete.Data.Upserts.Should().NotContain(e => e.Id == eventId);
    }

    [Fact]
    public async Task Changes_rejects_a_negative_since_cursor()
    {
        var client = await factory.CreateAuthenticatedClientAsync("events.changes-invalid@example.com");

        var response = await client.GetAsync("/api/v1/Events/changes?since=-1");

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task Changes_rejects_unauthenticated_requests()
    {
        var client = factory.CreateClient();

        var response = await client.GetAsync("/api/v1/Events/changes");

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    private static async Task<ServiceResult<T>> DeserializeAsync<T>(HttpResponseMessage response)
    {
        var result = await response.Content.ReadFromJsonAsync<ServiceResult<T>>(JsonOptions);
        return result!;
    }
}
