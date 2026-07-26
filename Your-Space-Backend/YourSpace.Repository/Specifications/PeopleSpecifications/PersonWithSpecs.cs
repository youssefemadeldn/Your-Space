using System.Linq.Expressions;
using YourSpace.Data.Entities;
using YourSpace.Repository.Specifications.Paginated;

namespace YourSpace.Repository.Specifications.PeopleSpecifications;

public class PersonWithSpecs : BaseSpecification<Person>
{
    // Single person, scoped to its owner
    public PersonWithSpecs(int id, string ownerUserId)
        : base(p => p.Id == id && p.OwnerUserId == ownerUserId && p.DeletedAt == null)
    {
        AddInclude(p => p.Group);
    }

    // All persons in one group, unpaginated — feeds "add whole group at once" to an event
    public PersonWithSpecs(string ownerUserId, int groupId)
        : base(BuildPredicate(ownerUserId, groupId, null))
    {
    }

    // Count for the paginated list (no Skip/Take — see PaginationSpecification's count/list pairing note)
    public PersonWithSpecs(string ownerUserId, int? groupId, string? search)
        : base(BuildPredicate(ownerUserId, groupId, search))
    {
    }

    // Paginated list
    public PersonWithSpecs(string ownerUserId, int? groupId, string? search, PaginationSpecification paging)
        : base(BuildPredicate(ownerUserId, groupId, search))
    {
        AddInclude(p => p.Group);
        ApplyOrderBy(p => p.Name);
        ApplyPaging(paging.PageSize * (paging.PageIndex - 1), paging.PageSize);
    }

    // Explicit id list, optionally filtered by group — feeds reciprocity-candidate resolution
    // (the candidate PersonIds come from PersonOccasionHistoryWithSpecs.ReciprocityCandidates,
    // this spec then loads the actual Person rows for the ones not yet on the event).
    public PersonWithSpecs(string ownerUserId, List<int> personIds, int? groupId)
        : base(p => p.OwnerUserId == ownerUserId
            && p.DeletedAt == null
            && personIds.Contains(p.Id)
            && (groupId == null || p.GroupId == groupId))
    {
        AddInclude(p => p.Group);
    }

    private static Expression<Func<Person, bool>> BuildPredicate(string ownerUserId, int? groupId, string? search)
        => p => p.OwnerUserId == ownerUserId
            && p.DeletedAt == null
            && (groupId == null || p.GroupId == groupId)
            && (string.IsNullOrWhiteSpace(search) || p.Name.Contains(search));
}
