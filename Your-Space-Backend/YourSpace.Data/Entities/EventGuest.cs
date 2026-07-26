using YourSpace.Data.Enums;

namespace YourSpace.Data.Entities;

// Join row between Event and Person — hard-deletable (no DeletedAt). EventGuestStatus.Skipped
// already covers "deliberately excluded but still tracked"; a real delete here is for
// "added by mistake", so no soft-delete safety net is needed the way Person/Group/Event have one.
public class EventGuest
{
    public int Id { get; set; }

    public required int EventId { get; set; }
    public required int PersonId { get; set; }

    public EventGuestStatus Status { get; set; } = EventGuestStatus.NotInvited;

    // Chosen live, at the moment of actually inviting this person — never set at Person-creation time.
    public InviteMethod? InviteMethod { get; set; }

    public DateTime? InvitedAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public Event Event { get; set; } = null!;
    public Person Person { get; set; } = null!;
}
