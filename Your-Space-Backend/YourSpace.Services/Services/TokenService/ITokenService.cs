using YourSpace.Data.Entities;

namespace YourSpace.Services.Services.TokenService;

public interface ITokenService
{
    (string AccessToken, DateTime ExpiresAt) GenerateAccessToken(AppUser user, IList<string> roles);
    string GenerateRefreshToken();
    string HashToken(string token);
}
