using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.GroupService.Dtos;

namespace YourSpace.Services.Services.GroupService;

public interface IGroupService
{
    Task<ServiceResult<GroupDetailsDto>> GetDetailsAsync(string ownerUserId, int id);
    Task<ServiceResult<PaginatedResultDto<GroupProfileDto>>> GetAllAsync(string ownerUserId, string? search, PaginationSpecification pagination);
    Task<ServiceResult<GroupDetailsDto>> CreateAsync(string ownerUserId, CreateGroupDto dto);
    Task<ServiceResult<GroupDetailsDto>> UpdateAsync(string ownerUserId, UpdateGroupDto dto);
    Task<ServiceResult> DeleteAsync(string ownerUserId, int id);

    // Delta-sync pull (doc/local-first-sync-design.md §6, row 7.5). `since` is the caller's
    // last-seen SyncVersion cursor (0 on a first-ever sync); `pageSize` is clamped server-side.
    Task<ServiceResult<GroupChangesDto>> GetChangesAsync(string ownerUserId, long since, int pageSize);
}
