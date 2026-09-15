using YourSpace.Data.Enums;

namespace YourSpace.Services.Services.PersonRelationshipService.Dtos;

public class PersonRelationshipDetailsDto
{
    public required int Id { get; set; }
    public required int PersonId { get; set; }
    public required int RelatedPersonId { get; set; }
    public required string RelatedPersonName { get; set; }
    public required RelationType RelationType { get; set; }
    public required DateTime CreatedAt { get; set; }

    // The auto-derived inverse row's id/type (row 9.13) — lets the mobile client reconcile both
    // halves of the pair it optimistically created offline (its own PersonId/RelatedPersonId/
    // RelatedPersonName mirror what the caller already knows: RelatedPersonId and Person.Name).
    public required int InverseId { get; set; }
    public required RelationType InverseRelationType { get; set; }
}
