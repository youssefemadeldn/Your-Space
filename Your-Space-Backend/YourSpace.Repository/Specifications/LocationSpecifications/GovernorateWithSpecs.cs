using System.Linq.Expressions;
using YourSpace.Data.Entities;
using YourSpace.Repository.Specifications.Paginated;

namespace YourSpace.Repository.Specifications.LocationSpecifications;

public class GovernorateWithSpecs : BaseSpecification<Governorate>
{
    // Single governorate, visible if it's a shared/global row (OwnerUserId null) or owned by the caller
    public GovernorateWithSpecs(int id, string ownerUserId)
        : base(g => g.Id == id && (g.OwnerUserId == null || g.OwnerUserId == ownerUserId) && g.DeletedAt == null)
    {
    }

    // All governorates visible to the caller (global + their own), unpaginated
    public GovernorateWithSpecs(string ownerUserId)
        : base(g => (g.OwnerUserId == null || g.OwnerUserId == ownerUserId) && g.DeletedAt == null)
    {
        ApplyOrderBy(g => g.Name);
    }

    // Count for the paginated list
    public GovernorateWithSpecs(string ownerUserId, string? search)
        : base(BuildPredicate(ownerUserId, search))
    {
    }

    // Paginated list
    public GovernorateWithSpecs(string ownerUserId, string? search, PaginationSpecification paging)
        : base(BuildPredicate(ownerUserId, search))
    {
        ApplyOrderBy(g => g.Name);
        ApplyPaging(paging.PageSize * (paging.PageIndex - 1), paging.PageSize);
    }

    // Delta-sync "changes since" query (doc/local-first-sync-design.md §6) — deliberately no
    // DeletedAt filter: tombstones (soft-deleted rows) must be included so the caller can tell
    // the client to remove them. Widened OwnerUserId predicate (global-or-mine, same as every
    // other GovernorateWithSpecs overload) — a global row's SyncVersion is assigned exactly once
    // at seed time and never mutates again (locked rows can't reach Update/Delete), so it
    // surfaces once on a user's first-ever pull and never reappears. Ordered by SyncVersion, not
    // CreatedAt/UpdatedAt, so the cursor stays unambiguous even for two rows written in the same
    // millisecond.
    public GovernorateWithSpecs(string ownerUserId, long since, int pageSize)
        : base(g => (g.OwnerUserId == null || g.OwnerUserId == ownerUserId) && g.SyncVersion > since)
    {
        ApplyOrderBy(g => g.SyncVersion);
        ApplyPaging(0, pageSize);
    }

    private static Expression<Func<Governorate, bool>> BuildPredicate(string ownerUserId, string? search)
        => g => (g.OwnerUserId == null || g.OwnerUserId == ownerUserId)
            && g.DeletedAt == null
            && (string.IsNullOrWhiteSpace(search) || g.Name.Contains(search));
}
