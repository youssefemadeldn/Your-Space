namespace YourSpace.Services.Services.CityService.Dtos;

public class CityDetailsDto
{
    public required int Id { get; set; }
    public required int GovernorateId { get; set; }
    public required string Name { get; set; }
    public string? NameAr { get; set; }
    public required DateTime CreatedAt { get; set; }
}
