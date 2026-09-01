namespace YourSpace.Services.Services.AuthService.Dtos;

public class DeleteAccountDto
{
    // Re-authentication before an irreversible action — the caller re-enters their current password.
    public required string Password { get; set; }
}
