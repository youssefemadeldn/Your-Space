using YourSpace.Services.Helper;
using YourSpace.Services.Services.UserSettingsService.Dtos;

namespace YourSpace.Services.Services.UserSettingsService;

public interface IUserSettingsService
{
    Task<ServiceResult<UserSettingsDetailsDto>> GetAsync(string userId);
    Task<ServiceResult<UserSettingsDetailsDto>> UpdateAsync(string userId, UpdateUserSettingsDto dto);
}
