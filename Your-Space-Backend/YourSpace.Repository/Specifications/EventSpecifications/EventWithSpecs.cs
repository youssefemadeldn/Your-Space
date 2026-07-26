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

    private static Expression<Func<Event, bool>> BuildPredicate(string ownerUserId, string? search)
        => e => e.OwnerUserId == ownerUserId
            && e.DeletedAt == null
            && (string.IsNullOrWhiteSpace(search) || e.Name.Contains(search));
}
