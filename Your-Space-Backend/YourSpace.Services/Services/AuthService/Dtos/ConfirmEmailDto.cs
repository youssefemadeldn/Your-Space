namespace YourSpace.Services.Services.AuthService.Dtos;

public class ConfirmEmailDto
{
    public required string Email { get; set; }
    public required string Code { get; set; }
}
