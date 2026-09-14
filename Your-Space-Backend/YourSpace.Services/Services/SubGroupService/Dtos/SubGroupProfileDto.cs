namespace YourSpace.Services.Services.SubGroupService.Dtos;

public class SubGroupProfileDto
{
    public required int Id { get; set; }
    public required int GroupId { get; set; }
    public required string Name { get; set; }
    public string? NameAr { get; set; }

    // Management-screen row caption ("{n} people") and the Add-Guests-by-subgroup tab caption —
    // computed in-service from a single batch Person query, not N+1 per row.
    public required int PersonCount { get; set; }

    // Delta-sync fields (doc/local-first-sync-design.md §6, row 8.17) — needed by the mobile
    // client's local drift cache the same way CityProfileDto's already are.
    public required DateTime UpdatedAt { get; set; }
    public required long SyncVersion { get; set; }
}
