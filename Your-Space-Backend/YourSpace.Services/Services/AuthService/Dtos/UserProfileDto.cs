using YourSpace.Data.Enums;

namespace YourSpace.Services.Services.AuthService.Dtos;

public class UserProfileDto
{
    public required string Id { get; set; }
    public required string Email { get; set; }
    public required string FirstName { get; set; }
    public required string LastName { get; set; }
    public string? PhoneNumber { get; set; }
    public required Gender Gender { get; set; }

    // Presigned, resolved in-service (never a plain AutoMapper member-map — it's an async R2 call) —
    // null when the user has no avatar set. Expires per R2Settings.PresignedUrlExpiryHours.
    public string? AvatarUrl { get; set; }

    public required IList<string> Roles { get; set; }
}
