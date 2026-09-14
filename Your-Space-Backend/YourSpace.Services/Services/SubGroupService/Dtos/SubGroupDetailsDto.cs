namespace YourSpace.Services.Services.SubGroupService.Dtos;

public class SubGroupDetailsDto
{
    public required int Id { get; set; }
    public required int GroupId { get; set; }
    public required string Name { get; set; }
    public string? NameAr { get; set; }
    public required DateTime CreatedAt { get; set; }

    // Delta-sync fields (doc/local-first-sync-design.md §6, row 8.17).
    public required DateTime UpdatedAt { get; set; }
    public required long SyncVersion { get; set; }
}
