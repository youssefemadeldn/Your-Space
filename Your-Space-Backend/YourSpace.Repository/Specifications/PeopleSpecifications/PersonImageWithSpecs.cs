using System.Linq.Expressions;
using YourSpace.Data.Entities;

namespace YourSpace.Repository.Specifications.PeopleSpecifications;

public class PersonImageWithSpecs : BaseSpecification<PersonImage>
{
    private PersonImageWithSpecs(Expression<Func<PersonImage, bool>> criteria)
        : base(criteria)
    {
    }

    // Single image — scoped to both the specific parent Person (defense in depth against a route
    // personId that doesn't actually match the image's real parent) and its owner.
    public static PersonImageWithSpecs ById(int id, int personId, string ownerUserId)
        => new(i => i.Id == id && i.PersonId == personId && i.Person.OwnerUserId == ownerUserId);

    // All of one person's images — primary first, then oldest. No pagination: hard-capped at 6 rows.
    public static PersonImageWithSpecs ForPerson(int personId, string ownerUserId)
    {
        var spec = new PersonImageWithSpecs(BuildForPersonPredicate(personId, ownerUserId));
        spec.ApplyOrderByDescending(i => i.IsPrimary);
        return spec;
    }

    private static Expression<Func<PersonImage, bool>> BuildForPersonPredicate(int personId, string ownerUserId)
        => i => i.PersonId == personId && i.Person.OwnerUserId == ownerUserId;
}
