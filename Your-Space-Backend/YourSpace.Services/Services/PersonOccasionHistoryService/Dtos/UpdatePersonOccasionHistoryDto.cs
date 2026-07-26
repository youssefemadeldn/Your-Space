using YourSpace.Data.Enums;

namespace YourSpace.Services.Services.PersonOccasionHistoryService.Dtos;

public class UpdatePersonOccasionHistoryDto
{
    public required int Id { get; set; }

    // Null on any of the below means "leave unchanged".
    public bool? InvitedMe { get; set; }
    public InviteMethod? InviteMethod { get; set; }
    public string? OccasionName { get; set; }
    public DateTime? OccasionDate { get; set; }
    public string? Notes { get; set; }
}
