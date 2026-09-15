using System.ComponentModel.DataAnnotations;

namespace YourSpace.Data.Entities;

public class Event
{
    public int Id { get; set; }

    public required string OwnerUserId { get; set; }

    [MaxLength(200)]
    public required string Name { get; set; }

    [MaxLength(200)]
    public string? NameAr { get; set; }

    public DateTime? EventDate { get; set; }

    [MaxLength(2000)]
    public string? Notes { get; set; }

    public DateTime? DeletedAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Monotonic delta-sync cursor (doc/local-first-sync-design.md §6) — bumped explicitly by
    // ISyncVersionProvider/EventService on every create/update/soft-delete, never left to its
    // column default after the first write.
    public long SyncVersion { get; set; }

    public AppUser Owner { get; set; } = null!;
}
