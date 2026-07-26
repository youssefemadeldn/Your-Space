using System.ComponentModel.DataAnnotations;
using YourSpace.Data.Enums;

namespace YourSpace.Data.Entities;

// Reciprocity history — a log row recording whether this Person invited the user to one of their
// own past occasions, and how. Independent of any of the user's own Events. Hard-deletable log row.
public class PersonOccasionHistory
{
    public int Id { get; set; }

    public required int PersonId { get; set; }

    public required bool InvitedMe { get; set; }

    // Only meaningful when InvitedMe == true — enforced server-side (validator + service guard).
    public InviteMethod? InviteMethod { get; set; }

    [MaxLength(200)]
    public string? OccasionName { get; set; }

    public DateTime? OccasionDate { get; set; }

    [MaxLength(2000)]
    public string? Notes { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public Person Person { get; set; } = null!;
}
