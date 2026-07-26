using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.EventService.Dtos;

namespace YourSpace.Services.Services.EventService;

public interface IEventService
{
    Task<ServiceResult<EventDetailsDto>> GetDetailsAsync(string ownerUserId, int id);
    Task<ServiceResult<PaginatedResultDto<EventProfileDto>>> GetAllAsync(string ownerUserId, string? search, PaginationSpecification pagination);
    Task<ServiceResult<EventDetailsDto>> CreateAsync(string ownerUserId, CreateEventDto dto);
    Task<ServiceResult<EventDetailsDto>> UpdateAsync(string ownerUserId, UpdateEventDto dto);
    Task<ServiceResult> DeleteAsync(string ownerUserId, int id);
}
