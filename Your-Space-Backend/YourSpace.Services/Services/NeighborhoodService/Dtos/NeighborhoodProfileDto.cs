namespace YourSpace.Services.Services.NeighborhoodService.Dtos;

public class NeighborhoodProfileDto
{
    public required int Id { get; set; }
    public required int CityId { get; set; }
    public required string Name { get; set; }
    public string? NameAr { get; set; }

    // Management-screen row caption ("{n} people") — Neighborhood is the leaf of the location
    // hierarchy, so unlike City its count is people directly, not a child entity.
    public required int PersonCount { get; set; }
}
