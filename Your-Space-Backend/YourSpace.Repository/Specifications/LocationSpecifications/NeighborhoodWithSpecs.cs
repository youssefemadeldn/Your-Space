using System.Linq.Expressions;
using YourSpace.Data.Entities;
using YourSpace.Repository.Specifications.Paginated;

namespace YourSpace.Repository.Specifications.LocationSpecifications;

public class NeighborhoodWithSpecs : BaseSpecification<Neighborhood>
{
    // Single neighborhood, scoped to its parent city and owner
    public NeighborhoodWithSpecs(int id, int cityId, string ownerUserId)
        : base(n => n.Id == id && n.CityId == cityId && n.OwnerUserId == ownerUserId && n.DeletedAt == null)
    {
    }

    // Single neighborhood, scoped only by owner (city-agnostic) — used when a caller only has the
    // neighborhood id at hand (e.g. the bulk-add-guests-by-neighborhood existence check).
    public NeighborhoodWithSpecs(int id, string ownerUserId)
        : base(n => n.Id == id && n.OwnerUserId == ownerUserId && n.DeletedAt == null)
    {
    }

    // All neighborhoods for one city, unpaginated
    public NeighborhoodWithSpecs(string ownerUserId, int cityId)
        : base(n => n.OwnerUserId == ownerUserId && n.CityId == cityId && n.DeletedAt == null)
    {
        ApplyOrderBy(n => n.Name);
    }

    // Every neighborhood for the owner, regardless of city — feeds CityService's in-memory
    // per-city neighborhood-count computation (one query instead of N, mirrors
    // EventGuestService.GetProgressAsync's "load everything once, count in-memory" pattern).
    public NeighborhoodWithSpecs(string ownerUserId)
        : base(n => n.OwnerUserId == ownerUserId && n.DeletedAt == null)
    {
        ApplyOrderBy(n => n.Name);
    }

    // Count for the paginated list
    public NeighborhoodWithSpecs(string ownerUserId, int cityId, string? search)
        : base(BuildPredicate(ownerUserId, cityId, search))
    {
    }

    // Paginated list
    public NeighborhoodWithSpecs(string ownerUserId, int cityId, string? search, PaginationSpecification paging)
        : base(BuildPredicate(ownerUserId, cityId, search))
    {
        ApplyOrderBy(n => n.Name);
        ApplyPaging(paging.PageSize * (paging.PageIndex - 1), paging.PageSize);
    }

    private static Expression<Func<Neighborhood, bool>> BuildPredicate(string ownerUserId, int cityId, string? search)
        => n => n.OwnerUserId == ownerUserId
            && n.CityId == cityId
            && n.DeletedAt == null
            && (string.IsNullOrWhiteSpace(search) || n.Name.Contains(search));
}
