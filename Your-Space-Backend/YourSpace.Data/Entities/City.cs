using System.ComponentModel.DataAnnotations;

namespace YourSpace.Data.Entities;

// Level 2 of the location hierarchy. Always user-owned (unlike Governorate) — no lock concept.
public class City
{
    public int Id { get; set; }

    public required string OwnerUserId { get; set; }

    public required int GovernorateId { get; set; }

    [MaxLength(200)]
    public required string Name { get; set; }

    [MaxLength(200)]
    public string? NameAr { get; set; }

    public DateTime? DeletedAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Monotonic delta-sync cursor (doc/local-first-sync-design.md §6) — NOT a wall-clock value.
    // Assigned from the "Cities_SyncVersion_seq" Postgres sequence via ISyncVersionProvider on
    // every create/update/soft-delete (CityService), never left to its column default after
    // the first write. UpdatedAt alone can't serve this role: two rows updated in the same
    // millisecond must never be ambiguous to a `WHERE SyncVersion > @since` pull.
    public long SyncVersion { get; set; }

    public AppUser Owner { get; set; } = null!;
    public Governorate Governorate { get; set; } = null!;
}
