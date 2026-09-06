using YourSpace.Services.Helper;
using YourSpace.Services.Services.PersonImageService.Dtos;

namespace YourSpace.Services.Services.PersonImageService;

public interface IPersonImageService
{
    Task<ServiceResult<IReadOnlyList<PersonImageDto>>> GetAllAsync(string ownerUserId, int personId);
    Task<ServiceResult<PersonImageDto>> UploadAsync(string ownerUserId, int personId, UploadPersonImageDto dto);
    Task<ServiceResult> DeleteAsync(string ownerUserId, int personId, int imageId);
    Task<ServiceResult<PersonImageDto>> SetPrimaryAsync(string ownerUserId, int personId, int imageId);
}
