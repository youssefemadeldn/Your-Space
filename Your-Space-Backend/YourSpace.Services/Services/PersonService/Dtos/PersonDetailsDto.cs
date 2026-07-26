using YourSpace.Services.Services.PersonOccasionHistoryService.Dtos;

namespace YourSpace.Services.Services.PersonService.Dtos;

public class PersonDetailsDto
{
    public required int Id { get; set; }
    public required string Name { get; set; }
    public string? PhoneNumber { get; set; }
    public required int GroupId { get; set; }
    public required string GroupName { get; set; }
    public required bool HasReciprocityHistory { get; set; }
    public required IReadOnlyList<PersonOccasionHistoryProfileDto> OccasionHistory { get; set; }
    public required DateTime CreatedAt { get; set; }
}
