using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.NeighborhoodService.Dtos;

namespace YourSpace.Services.Services.NeighborhoodService;

public interface INeighborhoodService
{
    Task<ServiceResult<NeighborhoodDetailsDto>> GetDetailsAsync(string ownerUserId, int cityId, int id);
    Task<ServiceResult<PaginatedResultDto<NeighborhoodProfileDto>>> GetAllAsync(string ownerUserId, int cityId, string? search, PaginationSpecification pagination);

    // Flat "all mine" pull (row 8.20) — city-agnostic, feeds mobile Tier 1's bulk local
    // population. No PersonCount enrichment — the richer nested GetAllAsync stays for the
    // management screen.
    Task<ServiceResult<PaginatedResultDto<NeighborhoodProfileDto>>> GetAllMineAsync(string ownerUserId, string? search, PaginationSpecification pagination);
    Task<ServiceResult<NeighborhoodDetailsDto>> CreateAsync(string ownerUserId, int cityId, CreateNeighborhoodDto dto);
    Task<ServiceResult<NeighborhoodDetailsDto>> UpdateAsync(string ownerUserId, int cityId, int id, UpdateNeighborhoodDto dto);
    Task<ServiceResult> DeleteAsync(string ownerUserId, int cityId, int id);

    Task<ServiceResult<NeighborhoodChangesDto>> GetChangesAsync(string ownerUserId, long since, int pageSize);
}
