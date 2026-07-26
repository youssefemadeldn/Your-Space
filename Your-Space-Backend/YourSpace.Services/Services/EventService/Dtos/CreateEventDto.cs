namespace YourSpace.Services.Services.EventService.Dtos;

public class CreateEventDto
{
    public required string Name { get; set; }
    public string? NameAr { get; set; }
    public DateTime? EventDate { get; set; }
    public string? Notes { get; set; }
}
