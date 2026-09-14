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

    // Flat "all mine" pull for the mobile Tier 1 bulk sync (doc/local-first-sync-design.md §11
    // row 8.8) — governorate-agnostic, no NeighborhoodCount/PersonCount enrichment (those stay
    // on the richer nested GetAllAsync the management screen uses).
    Task<ServiceResult<PaginatedResultDto<CityProfileDto>>> GetAllMineAsync(string ownerUserId, string? search, PaginationSpecification pagination);

    // Delta-sync pull (doc/local-first-sync-design.md §6, row 8.11). `since` is the caller's
    // last-seen SyncVersion cursor (0 on a first-ever sync); `pageSize` is clamped server-side.
    Task<ServiceResult<CityChangesDto>> GetChangesAsync(string ownerUserId, long since, int pageSize);
}
