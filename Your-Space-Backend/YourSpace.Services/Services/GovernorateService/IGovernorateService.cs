using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.GovernorateService.Dtos;

namespace YourSpace.Services.Services.GovernorateService;

public interface IGovernorateService
{
    Task<ServiceResult<GovernorateDetailsDto>> GetDetailsAsync(string ownerUserId, int id);
    Task<ServiceResult<PaginatedResultDto<GovernorateProfileDto>>> GetAllAsync(string ownerUserId, string? search, PaginationSpecification pagination);
    Task<ServiceResult<GovernorateDetailsDto>> CreateAsync(string ownerUserId, CreateGovernorateDto dto);
    Task<ServiceResult<GovernorateDetailsDto>> UpdateAsync(string ownerUserId, UpdateGovernorateDto dto);
    Task<ServiceResult> DeleteAsync(string ownerUserId, int id);
}
