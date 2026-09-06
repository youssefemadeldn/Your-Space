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

    private static Expression<Func<Governorate, bool>> BuildPredicate(string ownerUserId, string? search)
        => g => (g.OwnerUserId == null || g.OwnerUserId == ownerUserId)
            && g.DeletedAt == null
            && (string.IsNullOrWhiteSpace(search) || g.Name.Contains(search));
}
