using YourSpace.Data.Enums;

namespace YourSpace.Services.Services.PersonRelationshipService.Dtos;

public class PersonRelationshipProfileDto
{
    public required int Id { get; set; }

    // Present on every row — the nested per-person list (PersonRelationshipsController's default
    // GET) doesn't need it (the caller already knows personId from the route) but the flat
    // "all mine" endpoint (row 9.13/9.16) does, since it spans every person the owner has.
    public required int PersonId { get; set; }

    public required int RelatedPersonId { get; set; }
    public required string RelatedPersonName { get; set; }
    public required RelationType RelationType { get; set; }
    public int? InverseRelationshipId { get; set; }
}
