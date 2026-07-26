namespace YourSpace.Data.Entities;

// True 1:1 with AppUser — UserId is the primary key, not just a foreign key.
public class UserSettings
{
    public required string UserId { get; set; }

    // Off by default — reciprocity suggestions are a remembered UI preference, not access control
    // (the underlying suggestions query always works regardless of this flag).
    public bool ReciprocitySuggestionsEnabled { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public AppUser User { get; set; } = null!;
}
