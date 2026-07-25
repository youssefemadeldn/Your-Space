namespace YourSpace.Services.Services.AuthService.Dtos;

public class AuthResponseDto
{
    public required string AccessToken { get; set; }
    public required DateTime AccessTokenExpiresAt { get; set; }
    public required string RefreshToken { get; set; }
    public required UserProfileDto User { get; set; }
}
