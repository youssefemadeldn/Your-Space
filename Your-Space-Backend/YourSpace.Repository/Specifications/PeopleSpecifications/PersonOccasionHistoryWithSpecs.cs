using System.Linq.Expressions;
using YourSpace.Data.Entities;
using YourSpace.Repository.Specifications.Paginated;

namespace YourSpace.Repository.Specifications.PeopleSpecifications;

public class PersonOccasionHistoryWithSpecs : BaseSpecification<PersonOccasionHistory>
{
    private PersonOccasionHistoryWithSpecs(Expression<Func<PersonOccasionHistory, bool>> criteria)
        : base(criteria)
    {
    }

    // Paginated list of one person's own history
    public PersonOccasionHistoryWithSpecs(int personId, string ownerUserId, PaginationSpecification paging)
        : base(BuildForPersonPredicate(personId, ownerUserId))
    {
        ApplyOrderByDescending(h => h.CreatedAt);
        ApplyPaging(paging.PageSize * (paging.PageIndex - 1), paging.PageSize);
    }

    // Single history entry — scoped to both the specific parent Person (defense in depth against a
    // route/body personId that doesn't actually match the entry's real parent) and its owner.
    public static PersonOccasionHistoryWithSpecs ById(int id, int personId, string ownerUserId)
        => new(h => h.Id == id && h.PersonId == personId && h.Person.OwnerUserId == ownerUserId);

    // Count for the paginated list (no Skip/Take — see PaginationSpecification's count/list pairing note)
    public static PersonOccasionHistoryWithSpecs ForPerson(int personId, string ownerUserId)
    {
        var spec = new PersonOccasionHistoryWithSpecs(BuildForPersonPredicate(personId, ownerUserId));
        spec.ApplyOrderByDescending(h => h.CreatedAt);
        return spec;
    }

    // Unpaginated PersonIds of everyone who has ever invited the owner — feeds the reciprocity
    // candidate list in EventGuestService (projected to .Select(h => h.PersonId).Distinct() there).
    public static PersonOccasionHistoryWithSpecs ReciprocityCandidates(string ownerUserId)
        => new(h => h.Person.OwnerUserId == ownerUserId && h.InvitedMe);

    // Every history row the user owns via any of their people, unpaginated — feeds a full account
    // deletion (these log rows are removed before their parent People).
    public static PersonOccasionHistoryWithSpecs ForOwner(string ownerUserId)
        => new(h => h.Person.OwnerUserId == ownerUserId);

    private static Expression<Func<PersonOccasionHistory, bool>> BuildForPersonPredicate(int personId, string ownerUserId)
        => h => h.PersonId == personId && h.Person.OwnerUserId == ownerUserId;
}
