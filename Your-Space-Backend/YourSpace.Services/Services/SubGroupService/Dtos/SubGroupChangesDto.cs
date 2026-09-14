namespace YourSpace.Services.Services.SubGroupService.Dtos;

// Delta-sync response shape (doc/local-first-sync-design.md §6) — a page of everything that
// changed for the owner since `Cursor` was last seen: upserts (created/updated rows) and
// tombstones (soft-deleted row ids) in the same page, ordered by SyncVersion.
public class SubGroupChangesDto
{
    public required IReadOnlyList<SubGroupProfileDto> Upserts { get; set; }
    public required IReadOnlyList<int> TombstoneIds { get; set; }

    // Max SyncVersion returned in this page, or the request's `since` unchanged if the page was
    // empty — the caller stores this as its next watermark.
    public required long Cursor { get; set; }

    // True when this page was full (pageSize rows returned) — there may be more; the caller
    // should immediately pull again with `since = Cursor`.
    public required bool HasMore { get; set; }
}
