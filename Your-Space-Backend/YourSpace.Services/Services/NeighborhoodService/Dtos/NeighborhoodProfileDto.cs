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

    // Delta-sync fields (doc/local-first-sync-design.md §6, row 8.23) — needed by the mobile
    // client's local drift cache the same way CityProfileDto's already are.
    public required DateTime UpdatedAt { get; set; }
    public required long SyncVersion { get; set; }
}
