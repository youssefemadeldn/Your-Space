namespace YourSpace.Services.Services.EventService.Dtos;

public class EventProfileDto
{
    public required int Id { get; set; }
    public required string Name { get; set; }
    public string? NameAr { get; set; }
    public DateTime? EventDate { get; set; }
    public required int TotalGuestCount { get; set; }
}
