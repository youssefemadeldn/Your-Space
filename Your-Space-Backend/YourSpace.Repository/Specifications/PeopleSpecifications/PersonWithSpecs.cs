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
        AddClassificationIncludes(this);
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
        AddClassificationIncludes(this);
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

    // Count for the paginated People-screen listing (5 filter dimensions) — see PersonListFilter.
    public PersonWithSpecs(string ownerUserId, PersonListFilter filter)
        : base(BuildFilterPredicate(ownerUserId, filter))
    {
    }

    // Paginated People-screen listing
    public PersonWithSpecs(string ownerUserId, PersonListFilter filter, PaginationSpecification paging)
        : base(BuildFilterPredicate(ownerUserId, filter))
    {
        AddClassificationIncludes(this);
        ApplyOrderBy(p => p.Name);
        ApplyPaging(paging.PageSize * (paging.PageIndex - 1), paging.PageSize);
    }

    private static Expression<Func<Person, bool>> BuildPredicate(string ownerUserId, int? groupId, string? search)
        => p => p.OwnerUserId == ownerUserId
            && p.DeletedAt == null
            && (groupId == null || p.GroupId == groupId)
            && (string.IsNullOrWhiteSpace(search) || p.Name.Contains(search));

    private static Expression<Func<Person, bool>> BuildFilterPredicate(string ownerUserId, PersonListFilter filter)
        => p => p.OwnerUserId == ownerUserId
            && p.DeletedAt == null
            && (filter.GroupId == null || p.GroupId == filter.GroupId)
            && (filter.SubGroupId == null || p.SubGroupId == filter.SubGroupId)
            && (filter.GovernorateId == null || p.GovernorateId == filter.GovernorateId)
            && (filter.CityId == null || p.CityId == filter.CityId)
            && (filter.NeighborhoodId == null || p.NeighborhoodId == filter.NeighborhoodId)
            && (string.IsNullOrWhiteSpace(filter.Search) || p.Name.Contains(filter.Search));

    // ---- Bulk-add-guests-by-X: unpaginated, exact-match person-id resolution ----
    // Static factories, not more constructor overloads — the existing 2-arg (ownerUserId, groupId)
    // constructor above is already taken for by-group and can't be overloaded again with the same
    // shape. Mirrors PersonImageWithSpecs's static-factory precedent.

    public static PersonWithSpecs ForSubGroup(string ownerUserId, int subGroupId)
        => new(p => p.OwnerUserId == ownerUserId && p.DeletedAt == null && p.SubGroupId == subGroupId);

    public static PersonWithSpecs ForGovernorate(string ownerUserId, int governorateId)
        => new(p => p.OwnerUserId == ownerUserId && p.DeletedAt == null && p.GovernorateId == governorateId);

    public static PersonWithSpecs ForCity(string ownerUserId, int cityId)
        => new(p => p.OwnerUserId == ownerUserId && p.DeletedAt == null && p.CityId == cityId);

    public static PersonWithSpecs ForNeighborhood(string ownerUserId, int neighborhoodId)
        => new(p => p.OwnerUserId == ownerUserId && p.DeletedAt == null && p.NeighborhoodId == neighborhoodId);

    // Private ctor backing the 4 static factories above — a bare predicate, no paging/order/include.
    private PersonWithSpecs(Expression<Func<Person, bool>> criteria)
        : base(criteria)
    {
    }

    // Shared include list for every shape that maps to a DTO exposing classification names
    // (GroupName, SubGroupName, GovernorateName, CityName, NeighborhoodName) — extracted so all
    // three call sites stay in sync rather than drifting if a new classification field is added.
    private static void AddClassificationIncludes(PersonWithSpecs spec)
    {
        spec.AddInclude(p => p.Group);
        spec.AddInclude(p => p.SubGroup!);
        spec.AddInclude(p => p.Governorate);
        spec.AddInclude(p => p.City!);
        spec.AddInclude(p => p.Neighborhood!);
    }
}
