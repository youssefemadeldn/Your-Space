using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.CityService.Dtos;

namespace YourSpace.Services.Services.CityService;

public interface ICityService
{
    Task<ServiceResult<CityDetailsDto>> GetDetailsAsync(string ownerUserId, int governorateId, int id);
    Task<ServiceResult<PaginatedResultDto<CityProfileDto>>> GetAllAsync(string ownerUserId, int governorateId, string? search, PaginationSpecification pagination);
    Task<ServiceResult<CityDetailsDto>> CreateAsync(string ownerUserId, int governorateId, CreateCityDto dto);
    Task<ServiceResult<CityDetailsDto>> UpdateAsync(string ownerUserId, int governorateId, int id, UpdateCityDto dto);
    Task<ServiceResult> DeleteAsync(string ownerUserId, int governorateId, int id);
}
