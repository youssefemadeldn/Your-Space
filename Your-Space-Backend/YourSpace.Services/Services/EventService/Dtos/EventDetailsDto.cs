namespace YourSpace.Services.Services.EventService.Dtos;

public class EventDetailsDto
{
    public required int Id { get; set; }
    public required string Name { get; set; }
    public string? NameAr { get; set; }
    public DateTime? EventDate { get; set; }
    public string? Notes { get; set; }
    public required int TotalGuestCount { get; set; }
    public required int NotInvitedCount { get; set; }
    public required int InvitedCount { get; set; }
    public required int SkippedCount { get; set; }
    public required DateTime CreatedAt { get; set; }
}
