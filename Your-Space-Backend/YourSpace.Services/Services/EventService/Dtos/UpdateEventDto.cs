namespace YourSpace.Services.Services.EventService.Dtos;

public class UpdateEventDto
{
    public required int Id { get; set; }

    // Null on any of the below means "leave unchanged".
    public string? Name { get; set; }
    public string? NameAr { get; set; }
    public DateTime? EventDate { get; set; }
    public string? Notes { get; set; }
}
