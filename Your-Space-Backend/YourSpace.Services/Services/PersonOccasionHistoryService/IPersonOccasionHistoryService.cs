using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.PersonOccasionHistoryService.Dtos;

namespace YourSpace.Services.Services.PersonOccasionHistoryService;

public interface IPersonOccasionHistoryService
{
    Task<ServiceResult<PersonOccasionHistoryDetailsDto>> GetDetailsAsync(string ownerUserId, int personId, int id);
    Task<ServiceResult<PaginatedResultDto<PersonOccasionHistoryProfileDto>>> GetAllAsync(string ownerUserId, int personId, PaginationSpecification pagination);
    Task<ServiceResult<PersonOccasionHistoryDetailsDto>> CreateAsync(string ownerUserId, int personId, CreatePersonOccasionHistoryDto dto);
    Task<ServiceResult<PersonOccasionHistoryDetailsDto>> UpdateAsync(string ownerUserId, int personId, UpdatePersonOccasionHistoryDto dto);
    Task<ServiceResult> DeleteAsync(string ownerUserId, int personId, int id);
}
