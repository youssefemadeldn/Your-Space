namespace YourSpace.Services.Services.GroupService.Dtos;

public class GroupDetailsDto
{
    public required int Id { get; set; }
    public required string Name { get; set; }
    public string? NameAr { get; set; }
    public required DateTime CreatedAt { get; set; }

    // Delta-sync fields (doc/local-first-sync-design.md §6, row 7.5).
    public required DateTime UpdatedAt { get; set; }
    public required long SyncVersion { get; set; }
}
