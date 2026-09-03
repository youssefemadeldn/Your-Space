using YourSpace.Data.Enums;

namespace YourSpace.Services.Services.AuthService.Dtos;

public class UserProfileDto
{
    public required string Id { get; set; }
    public required string Email { get; set; }
    public required string FirstName { get; set; }
    public required string LastName { get; set; }
    public string? PhoneNumber { get; set; }
    public Gender? Gender { get; set; }
    public required IList<string> Roles { get; set; }
}
