using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Text.RegularExpressions;
using FluentAssertions;
using YourSpace.Data.Enums;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.AuthService.Dtos;
using YourSpace.WebAPI.Tests.Common;

namespace YourSpace.WebAPI.Tests.Integration.Controllers;

public class AuthControllerTests(TestWebApplicationFactory factory) : IClassFixture<TestWebApplicationFactory>
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web) { Converters = { new JsonStringEnumConverter() } };

    [Fact]
    public async Task Register_confirm_login_refresh_and_logout_happy_path_succeeds()
    {
        var client = factory.CreateClient();
        const string email = "integration.user@example.com";

        var registerResponse = await client.PostAsJsonAsync("/api/v1/Auth/register", new RegisterDto
        {
            Email = email,
            Password = "Str0ng!Pass",
            ConfirmPassword = "Str0ng!Pass",
            FirstName = "Integration",
            LastName = "Tester",
            PhoneNumber = "+201234567890",
            Gender = Gender.Male
        });
        registerResponse.StatusCode.Should().Be(HttpStatusCode.Created);

        var confirmationEmail = factory.EmailSender.SentEmails.Single(e => e.ToEmail == email);
        var confirmationCode = Regex.Match(confirmationEmail.HtmlBody, "<h2>(.+?)</h2>").Groups[1].Value.Trim();

        var confirmResponse = await client.PostAsJsonAsync("/api/v1/Auth/confirm-email", new ConfirmEmailDto
        {
            Email = email,
            Code = confirmationCode
        });
        confirmResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        var loginResponse = await client.PostAsJsonAsync("/api/v1/Auth/login", new LoginDto
        {
            Email = email,
            Password = "Str0ng!Pass"
        });
        loginResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var loginResult = await DeserializeAsync<AuthResponseDto>(loginResponse);
        loginResult.Data!.AccessToken.Should().NotBeNullOrEmpty();
        loginResult.Data.RefreshToken.Should().NotBeNullOrEmpty();

        using var authorizedRequest = new HttpRequestMessage(HttpMethod.Get, "/api/v1/Auth/me");
        authorizedRequest.Headers.Add("Authorization", $"Bearer {loginResult.Data.AccessToken}");
        var meResponse = await client.SendAsync(authorizedRequest);
        meResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        var refreshResponse = await client.PostAsJsonAsync("/api/v1/Auth/refresh-token", new RefreshTokenRequestDto
        {
            RefreshToken = loginResult.Data.RefreshToken
        });
        refreshResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var refreshResult = await DeserializeAsync<AuthResponseDto>(refreshResponse);
        refreshResult.Data!.RefreshToken.Should().NotBe(loginResult.Data.RefreshToken, "refresh tokens rotate on every use");

        // The original refresh token is now revoked — replaying it must be rejected, not silently accepted.
        var replayResponse = await client.PostAsJsonAsync("/api/v1/Auth/refresh-token", new RefreshTokenRequestDto
        {
            RefreshToken = loginResult.Data.RefreshToken
        });
        replayResponse.StatusCode.Should().Be(HttpStatusCode.Unauthorized);

        var logoutResponse = await client.PostAsJsonAsync("/api/v1/Auth/revoke-token", new RevokeTokenDto
        {
            RefreshToken = refreshResult.Data.RefreshToken
        });
        logoutResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        var refreshAfterLogoutResponse = await client.PostAsJsonAsync("/api/v1/Auth/refresh-token", new RefreshTokenRequestDto
        {
            RefreshToken = refreshResult.Data.RefreshToken
        });
        refreshAfterLogoutResponse.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Delete_me_permanently_removes_the_account_and_all_owned_data()
    {
        const string email = "delete.full.graph@example.com";
        const string password = "Str0ng!Pass";
        var client = await factory.CreateAuthenticatedClientAsync(email);

        // Full owned-data graph: Group ← Person (the RESTRICT edge), Event ← EventGuest → Person,
        // Person ← PersonOccasionHistory. Deleting the user must tear all of this down in FK-safe
        // order without tripping the Person → Group RESTRICT constraint.
        var groupId = await CreateAndGetIdAsync(client, "/api/v1/Groups", new { name = "Family" });
        var personId = await CreateAndGetIdAsync(client, "/api/v1/Persons", new { name = "Aunt May", gender = "Female", groupId });
        var eventId = await CreateAndGetIdAsync(client, "/api/v1/Events", new { name = "Birthday" });

        var addGuestResponse = await client.PostAsJsonAsync($"/api/v1/events/{eventId}/guests", new { personIds = new[] { personId } });
        addGuestResponse.IsSuccessStatusCode.Should().BeTrue();

        var addHistoryResponse = await client.PostAsJsonAsync($"/api/v1/persons/{personId}/occasion-history", new { invitedMe = false });
        addHistoryResponse.IsSuccessStatusCode.Should().BeTrue();

        using var deleteRequest = new HttpRequestMessage(HttpMethod.Delete, "/api/v1/Auth/me")
        {
            Content = JsonContent.Create(new DeleteAccountDto { Password = password })
        };
        var deleteResponse = await client.SendAsync(deleteRequest);
        deleteResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        // The account and its data are gone: the still-valid access token can no longer resolve a
        // profile, and the credentials no longer authenticate.
        var meResponse = await client.GetAsync("/api/v1/Auth/me");
        meResponse.StatusCode.Should().Be(HttpStatusCode.NotFound);

        var loginResponse = await client.PostAsJsonAsync("/api/v1/Auth/login", new LoginDto { Email = email, Password = password });
        loginResponse.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Delete_me_with_the_wrong_password_is_rejected_and_keeps_the_account()
    {
        const string email = "delete.wrong.password@example.com";
        var client = await factory.CreateAuthenticatedClientAsync(email);

        using var deleteRequest = new HttpRequestMessage(HttpMethod.Delete, "/api/v1/Auth/me")
        {
            Content = JsonContent.Create(new DeleteAccountDto { Password = "not-my-password" })
        };
        var deleteResponse = await client.SendAsync(deleteRequest);

        deleteResponse.StatusCode.Should().Be(HttpStatusCode.UnprocessableEntity);
        var deleteResult = await DeserializeAsync<object>(deleteResponse);
        deleteResult.ErrorCode.Should().Be("Auth.DeleteAccount.InvalidPassword");

        var meResponse = await client.GetAsync("/api/v1/Auth/me");
        meResponse.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    private static async Task<int> CreateAndGetIdAsync(HttpClient client, string url, object body)
    {
        var response = await client.PostAsJsonAsync(url, body);
        response.IsSuccessStatusCode.Should().BeTrue($"POST {url} should succeed");
        var result = await response.Content.ReadFromJsonAsync<ServiceResult<JsonElement>>(JsonOptions);
        return result!.Data.GetProperty("id").GetInt32();
    }

    private static async Task<ServiceResult<T>> DeserializeAsync<T>(HttpResponseMessage response)
    {
        var result = await response.Content.ReadFromJsonAsync<ServiceResult<T>>(JsonOptions);
        return result!;
    }
}
