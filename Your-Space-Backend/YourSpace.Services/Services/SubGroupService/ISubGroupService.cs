using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.SubGroupService.Dtos;

namespace YourSpace.Services.Services.SubGroupService;

public interface ISubGroupService
{
    Task<ServiceResult<SubGroupDetailsDto>> GetDetailsAsync(string ownerUserId, int groupId, int id);
    Task<ServiceResult<PaginatedResultDto<SubGroupProfileDto>>> GetAllAsync(string ownerUserId, int groupId, string? search, PaginationSpecification pagination);
    Task<ServiceResult<SubGroupDetailsDto>> CreateAsync(string ownerUserId, int groupId, CreateSubGroupDto dto);
    Task<ServiceResult<SubGroupDetailsDto>> UpdateAsync(string ownerUserId, int groupId, int id, UpdateSubGroupDto dto);
    Task<ServiceResult> DeleteAsync(string ownerUserId, int groupId, int id);
}
