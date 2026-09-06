namespace YourSpace.Services.Services.SubGroupService.Dtos;

public class SubGroupDetailsDto
{
    public required int Id { get; set; }
    public required int GroupId { get; set; }
    public required string Name { get; set; }
    public string? NameAr { get; set; }
    public required DateTime CreatedAt { get; set; }
}
