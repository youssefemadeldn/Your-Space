using YourSpace.Data.Enums;
using YourSpace.Services.Services.PersonOccasionHistoryService.Dtos;
using YourSpace.Services.Services.PersonRelationshipService.Dtos;

namespace YourSpace.Services.Services.PersonService.Dtos;

public class PersonDetailsDto
{
    public required int Id { get; set; }
    public required string Name { get; set; }
    public string? PhoneNumber { get; set; }
    public string? PhoneNumber2 { get; set; }
    public required Gender Gender { get; set; }
    public required int GroupId { get; set; }
    public required string GroupName { get; set; }
    public int? SubGroupId { get; set; }
    public string? SubGroupName { get; set; }
    public required int GovernorateId { get; set; }
    public required string GovernorateName { get; set; }
    public int? CityId { get; set; }
    public string? CityName { get; set; }
    public int? NeighborhoodId { get; set; }
    public string? NeighborhoodName { get; set; }
    public string? PrimaryPhotoUrl { get; set; }
    public string? Notes { get; set; }
    public required bool HasReciprocityHistory { get; set; }
    public required IReadOnlyList<PersonOccasionHistoryProfileDto> OccasionHistory { get; set; }
    public required IReadOnlyList<PersonRelationshipProfileDto> Relationships { get; set; }
    public required DateTime CreatedAt { get; set; }
}
