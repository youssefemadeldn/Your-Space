using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Identity;

using YourSpace.Data.Enums;

namespace YourSpace.Data.Entities;

public class AppUser : IdentityUser
{
    [MaxLength(100)]
    public required string FirstName { get; set; }

    [MaxLength(100)]
    public required string LastName { get; set; }

    public required Gender Gender { get; set; }

    // R2 object key in the private "your-space-users-avatars" bucket, never a URL — a URL is resolved
    // on demand via IR2StorageService.GetPresignedUrlAsync (a stored one would go stale on expiry).
    [MaxLength(300)]
    public string? AvatarObjectKey { get; set; }
}
