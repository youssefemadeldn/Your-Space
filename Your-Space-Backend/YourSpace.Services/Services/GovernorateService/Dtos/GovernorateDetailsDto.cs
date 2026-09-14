namespace YourSpace.Services.Services.GovernorateService.Dtos;

public class GovernorateDetailsDto
{
    public required int Id { get; set; }
    public required string Name { get; set; }
    public string? NameAr { get; set; }
    public required bool IsLocked { get; set; }
    public required DateTime CreatedAt { get; set; }

    // Delta-sync fields (doc/local-first-sync-design.md §6, row 8.5).
    public required DateTime UpdatedAt { get; set; }
    public required long SyncVersion { get; set; }
}
