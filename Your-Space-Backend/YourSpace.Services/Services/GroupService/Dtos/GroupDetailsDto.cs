namespace YourSpace.Services.Services.GroupService.Dtos;

public class GroupDetailsDto
{
    public required int Id { get; set; }
    public required string Name { get; set; }
    public string? NameAr { get; set; }
    public required DateTime CreatedAt { get; set; }
}
