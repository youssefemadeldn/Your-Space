using YourSpace.Data.Enums;

namespace YourSpace.Services.Services.PersonOccasionHistoryService.Dtos;

// No PersonId — it comes from the nested route (/persons/{personId}/occasion-history), not the body.
public class CreatePersonOccasionHistoryDto
{
    public required bool InvitedMe { get; set; }
    public InviteMethod? InviteMethod { get; set; }
    public string? OccasionName { get; set; }
    public DateTime? OccasionDate { get; set; }
    public string? Notes { get; set; }
}
