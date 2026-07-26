using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.EventService.Dtos;
using YourSpace.WebAPI.Tests.Common;

namespace YourSpace.WebAPI.Tests.Integration.Controllers;

public class EventsControllerTests(TestWebApplicationFactory factory) : IClassFixture<TestWebApplicationFactory>
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

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

    private static async Task<ServiceResult<T>> DeserializeAsync<T>(HttpResponseMessage response)
    {
        var result = await response.Content.ReadFromJsonAsync<ServiceResult<T>>(JsonOptions);
        return result!;
    }
}
