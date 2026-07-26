using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.UserSettingsService.Dtos;
using YourSpace.WebAPI.Tests.Common;

namespace YourSpace.WebAPI.Tests.Integration.Controllers;

public class UserSettingsControllerTests(TestWebApplicationFactory factory) : IClassFixture<TestWebApplicationFactory>
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    [Fact]
    public async Task Get_lazily_creates_default_settings_then_update_persists_the_toggle()
    {
        var client = await factory.CreateAuthenticatedClientAsync("user-settings.happy-path@example.com");

        var getResponse = await client.GetAsync("/api/v1/UserSettings");
        getResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var initial = await DeserializeAsync<UserSettingsDetailsDto>(getResponse);
        initial.Data!.ReciprocitySuggestionsEnabled.Should().BeFalse();

        var updateResponse = await client.PutAsJsonAsync("/api/v1/UserSettings", new UpdateUserSettingsDto { ReciprocitySuggestionsEnabled = true });
        updateResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        var getAfterUpdateResponse = await client.GetAsync("/api/v1/UserSettings");
        var afterUpdate = await DeserializeAsync<UserSettingsDetailsDto>(getAfterUpdateResponse);
        afterUpdate.Data!.ReciprocitySuggestionsEnabled.Should().BeTrue();
    }

    [Fact]
    public async Task Rejects_unauthenticated_requests()
    {
        var client = factory.CreateClient();

        var response = await client.GetAsync("/api/v1/UserSettings");

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    private static async Task<ServiceResult<T>> DeserializeAsync<T>(HttpResponseMessage response)
    {
        var result = await response.Content.ReadFromJsonAsync<ServiceResult<T>>(JsonOptions);
        return result!;
    }
}
