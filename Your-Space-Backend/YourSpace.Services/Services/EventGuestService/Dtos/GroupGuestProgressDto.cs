namespace YourSpace.Services.Services.EventGuestService.Dtos;

public class GroupGuestProgressDto
{
    public required int GroupId { get; set; }
    public required string GroupName { get; set; }

    // Total active Persons in this group (master-list total), regardless of whether they've been
    // added to this event yet — lets the client tell "haven't started this group" apart from
    // "finished this group".
    public required int TotalPersonsInGroup { get; set; }
    public required int GuestsAddedCount { get; set; }
    public required int NotInvitedCount { get; set; }
    public required int InvitedCount { get; set; }
    public required int SkippedCount { get; set; }
}
