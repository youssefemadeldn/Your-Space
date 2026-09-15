using System.Linq.Expressions;
using YourSpace.Data.Entities;
using YourSpace.Repository.Specifications.Paginated;

namespace YourSpace.Repository.Specifications.EventSpecifications;

public class EventWithSpecs : BaseSpecification<Event>
{
    // Single event, scoped to its owner
    public EventWithSpecs(int id, string ownerUserId)
        : base(e => e.Id == id && e.OwnerUserId == ownerUserId && e.DeletedAt == null)
    {
    }

    // Every event for the owner, including soft-deleted rows — feeds a full account deletion,
    // which must hard-delete even rows that were already soft-deleted.
    public EventWithSpecs(string ownerUserId, bool includeDeleted)
        : base(e => e.OwnerUserId == ownerUserId && (includeDeleted || e.DeletedAt == null))
    {
    }

    // Count for the paginated list (no Skip/Take — see PaginationSpecification's count/list pairing note)
    public EventWithSpecs(string ownerUserId, string? search)
        : base(BuildPredicate(ownerUserId, search))
    {
    }

    // Paginated list, most recently created first
    public EventWithSpecs(string ownerUserId, string? search, PaginationSpecification paging)
        : base(BuildPredicate(ownerUserId, search))
    {
        ApplyOrderByDescending(e => e.CreatedAt);
        ApplyPaging(paging.PageSize * (paging.PageIndex - 1), paging.PageSize);
    }

    // Delta-sync "changes since" query (doc/local-first-sync-design.md §6) — deliberately no
    // DeletedAt filter: tombstones (soft-deleted rows) must be included so the caller can tell
    // the client to remove them. Ordered by SyncVersion, not CreatedAt/UpdatedAt, so the cursor
    // stays unambiguous even for two rows written in the same millisecond.
    public EventWithSpecs(string ownerUserId, long since, int pageSize)
        : base(e => e.OwnerUserId == ownerUserId && e.SyncVersion > since)
    {
        ApplyOrderBy(e => e.SyncVersion);
        ApplyPaging(0, pageSize);
    }

    private static Expression<Func<Event, bool>> BuildPredicate(string ownerUserId, string? search)
        => e => e.OwnerUserId == ownerUserId
            && e.DeletedAt == null
            && (string.IsNullOrWhiteSpace(search) || e.Name.Contains(search));
}
