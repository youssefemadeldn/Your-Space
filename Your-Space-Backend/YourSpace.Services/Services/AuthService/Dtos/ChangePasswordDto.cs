namespace YourSpace.Services.Services.AuthService.Dtos;

public class ChangePasswordDto
{
    public required string CurrentPassword { get; set; }
    public required string NewPassword { get; set; }
    public required string ConfirmNewPassword { get; set; }
}
