using YourSpace.Data.Enums;

namespace YourSpace.Services.Services.PersonService.Dtos;

public class CreatePersonDto
{
    public required string Name { get; set; }
    public string? PhoneNumber { get; set; }
    public string? PhoneNumber2 { get; set; }
    public required Gender Gender { get; set; }
    public required int GroupId { get; set; }
    public int? SubGroupId { get; set; }
    public required int GovernorateId { get; set; }
    public int? CityId { get; set; }
    public int? NeighborhoodId { get; set; }
    public string? Notes { get; set; }
}
