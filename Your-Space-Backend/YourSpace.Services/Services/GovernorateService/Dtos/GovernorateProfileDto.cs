namespace YourSpace.Services.Services.GovernorateService.Dtos;

public class GovernorateProfileDto
{
    public required int Id { get; set; }
    public required string Name { get; set; }
    public string? NameAr { get; set; }
    public required bool IsLocked { get; set; }

    // No mobile management screen consumes this today (Governorate has none), but the
    // Add-Guests-by-governorate tab does — computed in-service, not N+1 per row.
    public required int PersonCount { get; set; }

    // Delta-sync fields (doc/local-first-sync-design.md §6, row 8.5) — needed by the mobile
    // client's local drift cache the same way GroupProfileDto's already are.
    public required DateTime UpdatedAt { get; set; }
    public required long SyncVersion { get; set; }
}
