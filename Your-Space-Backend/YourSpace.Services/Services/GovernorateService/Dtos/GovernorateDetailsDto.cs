namespace YourSpace.Services.Services.GovernorateService.Dtos;

public class GovernorateDetailsDto
{
    public required int Id { get; set; }
    public required string Name { get; set; }
    public string? NameAr { get; set; }
    public required bool IsLocked { get; set; }
    public required DateTime CreatedAt { get; set; }
}
