using YourSpace.Data.Enums;

namespace YourSpace.Services.Services.EventGuestService.Dtos;

public class EventGuestDetailsDto
{
    public required int Id { get; set; }
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
