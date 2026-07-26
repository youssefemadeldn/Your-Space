using Microsoft.Extensions.Logging;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.UserSettingsService.Dtos;

namespace YourSpace.Services.Services.UserSettingsService;

public class UserSettingsService(
    IUnitOfWork unitOfWork,
    ILogger<UserSettingsService> logger) : IUserSettingsService
{
    public async Task<ServiceResult<UserSettingsDetailsDto>> GetAsync(string userId)
    {
        var settings = await GetOrCreateAsync(userId);
        return ServiceResult<UserSettingsDetailsDto>.Ok(BuildDto(settings));
    }

    public async Task<ServiceResult<UserSettingsDetailsDto>> UpdateAsync(string userId, UpdateUserSettingsDto dto)
    {
        var settings = await GetOrCreateAsync(userId);

        settings.ReciprocitySuggestionsEnabled = dto.ReciprocitySuggestionsEnabled;
        settings.UpdatedAt = DateTime.UtcNow;

        var repo = unitOfWork.Repository<UserSettings, string>();
        repo.Update(settings);
        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("Updated settings for user {UserId} — ReciprocitySuggestionsEnabled={Enabled}", userId, dto.ReciprocitySuggestionsEnabled);
        return ServiceResult<UserSettingsDetailsDto>.Ok(BuildDto(settings));
    }

    // Singleton per-user resource — no Create endpoint, no NotFound case. A user's first request
    // (GET or PUT) transparently provisions the row with the default (reciprocity suggestions off).
    private async Task<UserSettings> GetOrCreateAsync(string userId)
    {
        var repo = unitOfWork.Repository<UserSettings, string>();
        var settings = await repo.GetByIdAsync(userId);
        if (settings is not null)
        {
            return settings;
        }

        settings = new UserSettings { UserId = userId, ReciprocitySuggestionsEnabled = false };
        await repo.AddAsync(settings);
        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("Created default settings for user {UserId}", userId);
        return settings;
    }

    private static UserSettingsDetailsDto BuildDto(UserSettings settings) => new()
    {
        UserId = settings.UserId,
        ReciprocitySuggestionsEnabled = settings.ReciprocitySuggestionsEnabled,
        UpdatedAt = settings.UpdatedAt
    };
}
