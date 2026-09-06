using System.ComponentModel.DataAnnotations;

namespace YourSpace.Data.Entities;

// Level 1 of the location hierarchy (Governorate -> City -> Neighborhood), independent of
// Group/SubGroup. The only entity in this codebase with a nullable OwnerUserId: null means a
// shared/global row (seeded with Egypt's 27 governorates, IsLocked = true). A non-null
// OwnerUserId is a user's own custom governorate (IsLocked = false, fully editable by them).
// Every other entity here is strictly per-user — this dual shape is deliberate and new.
public class Governorate
{
    public int Id { get; set; }

    public string? OwnerUserId { get; set; }

    [MaxLength(200)]
    public required string Name { get; set; }

    [MaxLength(200)]
    public string? NameAr { get; set; }

    public required bool IsLocked { get; set; }

    public DateTime? DeletedAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public AppUser? Owner { get; set; }
}
