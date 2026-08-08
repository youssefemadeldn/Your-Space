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
}
