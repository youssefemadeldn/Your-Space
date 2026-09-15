using YourSpace.Data.Enums;

namespace YourSpace.Services.Services.EventGuestService.Dtos;

public class EventGuestProfileDto
{
    public required int Id { get; set; }

    // Present on every row — the nested per-event list (EventGuestsController's default GET)
    // doesn't need it (the caller already knows eventId from the route) but the flat "all mine"
    // endpoint (row 9.8) does, since it spans every event the owner has.
    public required int EventId { get; set; }

    public required int PersonId { get; set; }
    public required string PersonName { get; set; }
    public string? PersonPhoneNumber { get; set; }
    public required int GroupId { get; set; }
    public required string GroupName { get; set; }
    public required EventGuestStatus Status { get; set; }
    public InviteMethod? InviteMethod { get; set; }
    public DateTime? InvitedAt { get; set; }
}
