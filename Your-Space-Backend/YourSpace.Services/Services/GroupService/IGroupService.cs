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
}
