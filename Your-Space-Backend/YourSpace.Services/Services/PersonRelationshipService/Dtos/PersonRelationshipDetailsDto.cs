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
}
