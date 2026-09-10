namespace YourSpace.Services.Services.NeighborhoodService.Dtos;

public class NeighborhoodDetailsDto
{
    public required int Id { get; set; }
    public required int CityId { get; set; }
    public required string Name { get; set; }
    public string? NameAr { get; set; }
    public required DateTime CreatedAt { get; set; }
}
