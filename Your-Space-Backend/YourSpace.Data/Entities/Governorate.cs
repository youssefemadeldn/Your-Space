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

    // Monotonic delta-sync cursor (doc/local-first-sync-design.md §6) — NOT a wall-clock value.
    // Assigned from the "Governorates_SyncVersion_seq" Postgres sequence via ISyncVersionProvider
    // on every create/update/soft-delete (GovernorateService), never left to its column default
    // after the first write. UpdatedAt alone can't serve this role: two rows updated in the same
    // millisecond must never be ambiguous to a `WHERE SyncVersion > @since` pull. A locked/global
    // row's SyncVersion is assigned once at seed time (ReferenceDataSeeder) and never bumped
    // again — CheckEditable blocks any Update/Delete from ever reaching a locked row.
    public long SyncVersion { get; set; }

    public AppUser? Owner { get; set; }
}
