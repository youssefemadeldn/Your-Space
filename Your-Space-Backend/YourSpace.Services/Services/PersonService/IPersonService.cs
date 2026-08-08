using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.PersonService.Dtos;

namespace YourSpace.Services.Services.PersonService;

public interface IPersonService
{
    Task<ServiceResult<PersonDetailsDto>> GetDetailsAsync(string ownerUserId, int id);

    Task<ServiceResult<PaginatedResultDto<PersonProfileDto>>> GetAllAsync(
        string ownerUserId, int? groupId, int? subGroupId, int? governorateId, int? cityId, int? neighborhoodId,
        string? search, PaginationSpecification pagination);

    Task<ServiceResult<PersonDetailsDto>> CreateAsync(string ownerUserId, CreatePersonDto dto);
    Task<ServiceResult<PersonDetailsDto>> UpdateAsync(string ownerUserId, UpdatePersonDto dto);
    Task<ServiceResult> DeleteAsync(string ownerUserId, int id);
}
