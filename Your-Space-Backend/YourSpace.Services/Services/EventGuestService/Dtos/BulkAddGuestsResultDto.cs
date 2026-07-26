namespace YourSpace.Services.Services.EventGuestService.Dtos;

public class BulkAddGuestsResultDto
{
    public required int RequestedCount { get; set; }
    public required int AddedCount { get; set; }
    public required int AlreadyPresentCount { get; set; }
}
