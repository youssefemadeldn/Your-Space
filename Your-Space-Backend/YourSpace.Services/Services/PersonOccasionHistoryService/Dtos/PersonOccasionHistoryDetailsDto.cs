using YourSpace.Data.Enums;

namespace YourSpace.Services.Services.PersonOccasionHistoryService.Dtos;

public class PersonOccasionHistoryDetailsDto
{
    public required int Id { get; set; }
    public required int PersonId { get; set; }
    public required bool InvitedMe { get; set; }
    public InviteMethod? InviteMethod { get; set; }
    public string? OccasionName { get; set; }
    public DateTime? OccasionDate { get; set; }
    public string? Notes { get; set; }
    public required DateTime CreatedAt { get; set; }
}
