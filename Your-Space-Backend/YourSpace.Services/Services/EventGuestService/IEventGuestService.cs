using YourSpace.Data.Enums;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.EventGuestService.Dtos;
using YourSpace.Services.Services.PersonService.Dtos;

namespace YourSpace.Services.Services.EventGuestService;

public interface IEventGuestService
{
    Task<ServiceResult<EventGuestDetailsDto>> GetDetailsAsync(string ownerUserId, int eventId, int guestId);

    Task<ServiceResult<PaginatedResultDto<EventGuestProfileDto>>> GetListAsync(
        string ownerUserId, int eventId, int? groupId, EventGuestStatus? status, PaginationSpecification pagination);

    Task<ServiceResult<EventGuestProgressSummaryDto>> GetProgressAsync(string ownerUserId, int eventId);

    Task<ServiceResult<PaginatedResultDto<PersonProfileDto>>> GetReciprocitySuggestionsAsync(
        string ownerUserId, int eventId, int? groupId, PaginationSpecification pagination);

    Task<ServiceResult<BulkAddGuestsResultDto>> AddPersonsAsync(string ownerUserId, int eventId, AddPersonsToEventDto dto);
    Task<ServiceResult<BulkAddGuestsResultDto>> AddGroupAsync(string ownerUserId, int eventId, int groupId);

    Task<ServiceResult<EventGuestDetailsDto>> MarkInvitedAsync(string ownerUserId, int eventId, int guestId, MarkGuestInvitedDto dto);
    Task<ServiceResult<EventGuestDetailsDto>> MarkSkippedAsync(string ownerUserId, int eventId, int guestId);
    Task<ServiceResult<EventGuestDetailsDto>> RevertAsync(string ownerUserId, int eventId, int guestId);

    Task<ServiceResult> RemoveGuestAsync(string ownerUserId, int eventId, int guestId);
}
