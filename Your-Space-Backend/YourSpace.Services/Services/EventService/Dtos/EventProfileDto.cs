namespace YourSpace.Services.Services.EventService.Dtos;

public class EventProfileDto
{
    public required int Id { get; set; }
    public required string Name { get; set; }
    public string? NameAr { get; set; }
    public DateTime? EventDate { get; set; }
    public required int TotalGuestCount { get; set; }

    // Delta-sync fields (doc/local-first-sync-design.md §6, row 9.5) — needed by the mobile
    // client's local drift cache the same way GroupProfileDto's already are.
    public required DateTime UpdatedAt { get; set; }
    public required long SyncVersion { get; set; }
}
