using System.Linq.Expressions;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;

namespace YourSpace.Repository.Specifications.PeopleSpecifications;

public class PersonRelationshipWithSpecs : BaseSpecification<PersonRelationship>
{
    private PersonRelationshipWithSpecs(Expression<Func<PersonRelationship, bool>> criteria)
        : base(criteria)
    {
    }

    // Single relationship — scoped to both its owning Person (defense in depth against a route
    // personId that doesn't actually match) and its owner.
    public static PersonRelationshipWithSpecs ById(int id, int personId, string ownerUserId)
        => new(r => r.Id == id && r.PersonId == personId && r.Person.OwnerUserId == ownerUserId);

    // All of one person's outgoing relationships, with the related person's data included for
    // display (name, etc.) — ordered oldest-first.
    public static PersonRelationshipWithSpecs ForPerson(int personId, string ownerUserId)
    {
        var spec = new PersonRelationshipWithSpecs(
            r => r.PersonId == personId && r.Person.OwnerUserId == ownerUserId);
        spec.AddInclude(r => r.RelatedPerson);
        spec.ApplyOrderBy(r => r.CreatedAt);
        return spec;
    }

    // Feeds the "at most one incoming Father + one incoming Mother" guard clause.
    public static PersonRelationshipWithSpecs ByPersonAndType(int personId, string ownerUserId, RelationType type)
        => new(r => r.PersonId == personId && r.Person.OwnerUserId == ownerUserId && r.RelationType == type);

    // All Father/Mother/Son/Daughter edges for one owner — feeds in-memory cycle detection.
    public static PersonRelationshipWithSpecs ParentChildEdgesForOwner(string ownerUserId)
        => new(r => r.Person.OwnerUserId == ownerUserId
            && (r.RelationType == RelationType.Father
                || r.RelationType == RelationType.Mother
                || r.RelationType == RelationType.Son
                || r.RelationType == RelationType.Daughter));
}
