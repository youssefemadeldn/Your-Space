using YourSpace.Data.Enums;

namespace YourSpace.Services.Services.EventGuestService.Dtos;

public class MarkGuestInvitedDto
{
    public required InviteMethod InviteMethod { get; set; }
}
