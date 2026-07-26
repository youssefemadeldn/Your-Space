using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.RegularExpressions;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.AuthService.Dtos;

namespace YourSpace.WebAPI.Tests.Common;

// Shared register → confirm-email → login flow for integration tests of the new feature's
// controllers — every one of them requires an authenticated caller, so each test class would
// otherwise have to repeat AuthControllerTests's flow verbatim.
public static class AuthenticatedClientExtensions
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);
    private const string Password = "Str0ng!Pass";

    public static async Task<HttpClient> CreateAuthenticatedClientAsync(this TestWebApplicationFactory factory, string email)
    {
        var client = factory.CreateClient();

        await client.PostAsJsonAsync("/api/v1/Auth/register", new RegisterDto
        {
            Email = email,
            Password = Password,
            ConfirmPassword = Password,
            FirstName = "Test",
            LastName = "User",
            PhoneNumber = "+201234567890"
        });

        var confirmationEmail = factory.EmailSender.SentEmails.Last(e => e.ToEmail == email);
        var code = Regex.Match(confirmationEmail.HtmlBody, "<h2>(.+?)</h2>").Groups[1].Value.Trim();
        await client.PostAsJsonAsync("/api/v1/Auth/confirm-email", new ConfirmEmailDto { Email = email, Code = code });

        var loginResponse = await client.PostAsJsonAsync("/api/v1/Auth/login", new LoginDto { Email = email, Password = Password });
        var loginResult = await loginResponse.Content.ReadFromJsonAsync<ServiceResult<AuthResponseDto>>(JsonOptions);

        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", loginResult!.Data!.AccessToken);
        return client;
    }
}
