namespace YourSpace.Services.Services.GroupService.Dtos;

public class GroupProfileDto
{
    public required int Id { get; set; }
    public required string Name { get; set; }
    public string? NameAr { get; set; }

    // Delta-sync fields (doc/local-first-sync-design.md §6, row 7.5) — needed by the mobile
    // client's local drift cache the same way PersonProfileDto's already are.
    public required DateTime UpdatedAt { get; set; }
    public required long SyncVersion { get; set; }
}
