using System.Linq.Expressions;
using YourSpace.Data.Entities;
using YourSpace.Repository.Specifications.Paginated;

namespace YourSpace.Repository.Specifications.GroupSpecifications;

public class GroupWithSpecs : BaseSpecification<Group>
{
    // Single group, scoped to its owner
    public GroupWithSpecs(int id, string ownerUserId)
        : base(g => g.Id == id && g.OwnerUserId == ownerUserId && g.DeletedAt == null)
    {
    }

    // Every group for the owner, unpaginated — feeds the "every group appears in the progress
    // board, even ones with zero guests added yet" requirement.
    public GroupWithSpecs(string ownerUserId)
        : base(g => g.OwnerUserId == ownerUserId && g.DeletedAt == null)
    {
        ApplyOrderBy(g => g.Name);
    }

    // Count for the paginated list (no Skip/Take — see PaginationSpecification's count/list pairing note)
    public GroupWithSpecs(string ownerUserId, string? search)
        : base(BuildPredicate(ownerUserId, search))
    {
    }

    // Paginated list
    public GroupWithSpecs(string ownerUserId, string? search, PaginationSpecification paging)
        : base(BuildPredicate(ownerUserId, search))
    {
        ApplyOrderBy(g => g.Name);
        ApplyPaging(paging.PageSize * (paging.PageIndex - 1), paging.PageSize);
    }

    private static Expression<Func<Group, bool>> BuildPredicate(string ownerUserId, string? search)
        => g => g.OwnerUserId == ownerUserId
            && g.DeletedAt == null
            && (string.IsNullOrWhiteSpace(search) || g.Name.Contains(search));
}
