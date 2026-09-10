using YourSpace.Data.Enums;

namespace YourSpace.Data.Entities;

// A directed edge in the person-to-person kinship graph: "PersonId's relation to RelatedPersonId
// is RelationType" (e.g. PersonId=Y, RelatedPersonId=X, RelationType=Father reads as "Y's father
// is X"). Creating one auto-derives and creates its inverse on the other person's profile;
// InverseRelationshipId links the two rows explicitly so a delete can cascade to the mirror row
// without re-deriving it by content (two rows can legitimately share the same
// (PersonId, RelatedPersonId) pair with different RelationTypes, so content-matching is unsafe).
// Hard-deletable graph edge, no soft-delete/UpdatedAt — same precedent as PersonImage. An "edit"
// is delete-then-recreate, never an in-place update.
public class PersonRelationship
{
    public int Id { get; set; }

    public required int PersonId { get; set; }

    public required int RelatedPersonId { get; set; }

    public required RelationType RelationType { get; set; }

    public int? InverseRelationshipId { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Person Person { get; set; } = null!;
    public Person RelatedPerson { get; set; } = null!;
}
