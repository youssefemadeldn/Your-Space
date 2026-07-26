namespace YourSpace.Services.Services.EventGuestService.Dtos;

public class EventGuestProgressSummaryDto
{
    public required int EventId { get; set; }

    public required int TotalGuestCount { get; set; }
    public required int NotInvitedCount { get; set; }
    public required int InvitedCount { get; set; }
    public required int SkippedCount { get; set; }

    // Every one of the caller's groups appears here, even ones with zero guests added to this
    // event yet — so the client can render "haven't started this group" and support the
    // group-by-group workflow, which needs to see where it left off in each group, not just
    // the ones already touched.
    public required IReadOnlyList<GroupGuestProgressDto> Groups { get; set; }
}
