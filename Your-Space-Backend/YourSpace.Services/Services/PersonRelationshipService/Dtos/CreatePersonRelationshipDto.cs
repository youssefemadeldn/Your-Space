using YourSpace.Data.Enums;

namespace YourSpace.Services.Services.PersonRelationshipService.Dtos;

// PersonId deliberately isn't here — it comes from the route ({personId}/relationships), which is
// also why self-link/duplicate-parent/circular-chain checks live in the service as guard clauses,
// not validator rules (the validator never sees the route's personId).
public class CreatePersonRelationshipDto
{
    public required int RelatedPersonId { get; set; }
    public required RelationType RelationType { get; set; }
}
