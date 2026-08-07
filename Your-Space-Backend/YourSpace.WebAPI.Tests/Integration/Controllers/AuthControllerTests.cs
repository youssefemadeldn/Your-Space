using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.RegularExpressions;
using FluentAssertions;
using YourSpace.Data.Enums;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.AuthService.Dtos;
using YourSpace.WebAPI.Tests.Common;

namespace YourSpace.WebAPI.Tests.Integration.Controllers;

public class AuthControllerTests(TestWebApplicationFactory factory) : IClassFixture<TestWebApplicationFactory>
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

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

        using var updateProfileRequest = new HttpRequestMessage(HttpMethod.Put, "/api/v1/Auth/me")
        {
            Content = JsonContent.Create(new UpdateProfileDto
            {
                FirstName = "Updated",
                LastName = "Name",
                PhoneNumber = "+201111111111"
            })
        };
        updateProfileRequest.Headers.Add("Authorization", $"Bearer {loginResult.Data.AccessToken}");
        var updateProfileResponse = await client.SendAsync(updateProfileRequest);
        updateProfileResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var updateProfileResult = await DeserializeAsync<UserProfileDto>(updateProfileResponse);
        updateProfileResult.Data!.FirstName.Should().Be("Updated");
        updateProfileResult.Data.PhoneNumber.Should().Be("+201111111111");

        using var avatarContent = new MultipartFormDataContent();
        var avatarFileContent = new ByteArrayContent([0xFF, 0xD8, 0xFF, 0xE0]); // fake JPEG bytes — never actually decoded
        avatarFileContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue("image/jpeg");
        avatarContent.Add(avatarFileContent, "File", "avatar.jpg");
        using var uploadAvatarRequest = new HttpRequestMessage(HttpMethod.Post, "/api/v1/Auth/me/avatar") { Content = avatarContent };
        uploadAvatarRequest.Headers.Add("Authorization", $"Bearer {loginResult.Data.AccessToken}");
        var uploadAvatarResponse = await client.SendAsync(uploadAvatarRequest);
        uploadAvatarResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var uploadAvatarResult = await DeserializeAsync<UserProfileDto>(uploadAvatarResponse);
        uploadAvatarResult.Data!.AvatarUrl.Should().NotBeNullOrEmpty();

        using var removeAvatarRequest = new HttpRequestMessage(HttpMethod.Delete, "/api/v1/Auth/me/avatar");
        removeAvatarRequest.Headers.Add("Authorization", $"Bearer {loginResult.Data.AccessToken}");
        var removeAvatarResponse = await client.SendAsync(removeAvatarRequest);
        removeAvatarResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var removeAvatarResult = await DeserializeAsync<UserProfileDto>(removeAvatarResponse);
        removeAvatarResult.Data!.AvatarUrl.Should().BeNull();

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
    public async Task UpdateProfile_without_a_token_is_rejected()
    {
        var client = factory.CreateClient();

        var response = await client.PutAsJsonAsync("/api/v1/Auth/me", new UpdateProfileDto
        {
            FirstName = "No",
            LastName = "Auth",
            PhoneNumber = "+201234567890"
        });

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task UploadAvatar_without_a_token_is_rejected()
    {
        var client = factory.CreateClient();
        using var content = new MultipartFormDataContent();

        var response = await client.PostAsync("/api/v1/Auth/me/avatar", content);

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    private static async Task<ServiceResult<T>> DeserializeAsync<T>(HttpResponseMessage response)
    {
        var result = await response.Content.ReadFromJsonAsync<ServiceResult<T>>(JsonOptions);
        return result!;
    }
}
