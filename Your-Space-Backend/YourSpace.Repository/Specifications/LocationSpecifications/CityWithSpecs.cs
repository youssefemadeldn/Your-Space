using System.Linq.Expressions;
using YourSpace.Data.Entities;
using YourSpace.Repository.Specifications.Paginated;

namespace YourSpace.Repository.Specifications.LocationSpecifications;

public class CityWithSpecs : BaseSpecification<City>
{
    // Single city, scoped to its parent governorate and owner
    public CityWithSpecs(int id, int governorateId, string ownerUserId)
        : base(c => c.Id == id && c.GovernorateId == governorateId && c.OwnerUserId == ownerUserId && c.DeletedAt == null)
    {
    }

    // Single city, scoped only by owner (governorate-agnostic) — used when a caller only has the
    // city id at hand (e.g. NeighborhoodService validating its parent city belongs to the caller).
    public CityWithSpecs(int id, string ownerUserId)
        : base(c => c.Id == id && c.OwnerUserId == ownerUserId && c.DeletedAt == null)
    {
    }

    // All cities for one governorate, unpaginated
    public CityWithSpecs(string ownerUserId, int governorateId)
        : base(c => c.OwnerUserId == ownerUserId && c.GovernorateId == governorateId && c.DeletedAt == null)
    {
        ApplyOrderBy(c => c.Name);
    }

    // Count for the paginated list
    public CityWithSpecs(string ownerUserId, int governorateId, string? search)
        : base(BuildPredicate(ownerUserId, governorateId, search))
    {
    }

    // Paginated list
    public CityWithSpecs(string ownerUserId, int governorateId, string? search, PaginationSpecification paging)
        : base(BuildPredicate(ownerUserId, governorateId, search))
    {
        ApplyOrderBy(c => c.Name);
        ApplyPaging(paging.PageSize * (paging.PageIndex - 1), paging.PageSize);
    }

    private static Expression<Func<City, bool>> BuildPredicate(string ownerUserId, int governorateId, string? search)
        => c => c.OwnerUserId == ownerUserId
            && c.GovernorateId == governorateId
            && c.DeletedAt == null
            && (string.IsNullOrWhiteSpace(search) || c.Name.Contains(search));
}
