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

    // Flat "all mine" pull for the mobile Tier 1 bulk sync (doc/local-first-sync-design.md §11
    // row 8.14) — group-agnostic, no PersonCount enrichment (that stays on the richer nested
    // GetAllAsync the management screen uses).
    Task<ServiceResult<PaginatedResultDto<SubGroupProfileDto>>> GetAllMineAsync(string ownerUserId, string? search, PaginationSpecification pagination);

    // Delta-sync pull (doc/local-first-sync-design.md §6, row 8.17) — everything the owner's
    // subgroups changed since `since`, one page at a time.
    Task<ServiceResult<SubGroupChangesDto>> GetChangesAsync(string ownerUserId, long since, int pageSize);
}
