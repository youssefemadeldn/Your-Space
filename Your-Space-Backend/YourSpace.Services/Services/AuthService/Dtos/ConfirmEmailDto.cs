namespace YourSpace.Services.Services.AuthService.Dtos;

public class ConfirmEmailDto
{
    public required string UserId { get; set; }
    public required string Token { get; set; }
}
