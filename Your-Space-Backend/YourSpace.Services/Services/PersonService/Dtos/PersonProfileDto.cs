using YourSpace.Data.Enums;

namespace YourSpace.Services.Services.PersonService.Dtos;

public class PersonProfileDto
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
}
