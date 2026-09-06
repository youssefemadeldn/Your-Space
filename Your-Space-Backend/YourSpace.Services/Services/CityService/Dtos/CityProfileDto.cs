namespace YourSpace.Services.Services.CityService.Dtos;

public class CityProfileDto
{
    public required int Id { get; set; }
    public required int GovernorateId { get; set; }
    public required string Name { get; set; }
    public string? NameAr { get; set; }

    // Management-screen row caption ("{n} neighborhoods") — City is the one entity in this batch
    // whose caption counts a child entity, not people directly (it sits in the middle of the
    // 3-level location hierarchy).
    public required int NeighborhoodCount { get; set; }

    // Add-Guests-by-city tab caption — people whose CityId matches, inclusive of ones that also
    // have a NeighborhoodId set underneath it.
    public required int PersonCount { get; set; }
}
