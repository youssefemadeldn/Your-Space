using System.Linq.Expressions;
using YourSpace.Data.Entities;
using YourSpace.Repository.Specifications.Paginated;

namespace YourSpace.Repository.Specifications.GroupSpecifications;

public class SubGroupWithSpecs : BaseSpecification<SubGroup>
{
    // Single subgroup, scoped to its parent group and owner
    public SubGroupWithSpecs(int id, int groupId, string ownerUserId)
        : base(s => s.Id == id && s.GroupId == groupId && s.OwnerUserId == ownerUserId && s.DeletedAt == null)
    {
    }

    // Single subgroup, scoped only by owner (group-agnostic) — used when a caller only has the
    // subgroup id at hand (e.g. the bulk-add-guests-by-subgroup existence check).
    public SubGroupWithSpecs(int id, string ownerUserId)
        : base(s => s.Id == id && s.OwnerUserId == ownerUserId && s.DeletedAt == null)
    {
    }

    // All subgroups for one group, unpaginated
    public SubGroupWithSpecs(string ownerUserId, int groupId)
        : base(s => s.OwnerUserId == ownerUserId && s.GroupId == groupId && s.DeletedAt == null)
    {
        ApplyOrderBy(s => s.Name);
    }

    // Count for the paginated list
    public SubGroupWithSpecs(string ownerUserId, int groupId, string? search)
        : base(BuildPredicate(ownerUserId, groupId, search))
    {
    }

    // Paginated list
    public SubGroupWithSpecs(string ownerUserId, int groupId, string? search, PaginationSpecification paging)
        : base(BuildPredicate(ownerUserId, groupId, search))
    {
        ApplyOrderBy(s => s.Name);
        ApplyPaging(paging.PageSize * (paging.PageIndex - 1), paging.PageSize);
    }

    private static Expression<Func<SubGroup, bool>> BuildPredicate(string ownerUserId, int groupId, string? search)
        => s => s.OwnerUserId == ownerUserId
            && s.GroupId == groupId
            && s.DeletedAt == null
            && (string.IsNullOrWhiteSpace(search) || s.Name.Contains(search));
}
