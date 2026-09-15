using System.ComponentModel.DataAnnotations;

namespace YourSpace.Data.Entities;

// Level 3 (leaf) of the location hierarchy. Always user-owned, scoped to one parent City.
public class Neighborhood
{
    public int Id { get; set; }

    public required string OwnerUserId { get; set; }

    public required int CityId { get; set; }

    [MaxLength(200)]
    public required string Name { get; set; }

    [MaxLength(200)]
    public string? NameAr { get; set; }

    public DateTime? DeletedAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Monotonic delta-sync cursor (doc/local-first-sync-design.md §6) — NOT a wall-clock value.
    // Assigned from the "Neighborhoods_SyncVersion_seq" Postgres sequence via
    // ISyncVersionProvider on every create/update/soft-delete (NeighborhoodService), never left
    // to its column default after the first write. UpdatedAt alone can't serve this role: two
    // rows updated in the same millisecond must never be ambiguous to a
    // `WHERE SyncVersion > @since` pull.
    public long SyncVersion { get; set; }

    public AppUser Owner { get; set; } = null!;
    public City City { get; set; } = null!;
}
