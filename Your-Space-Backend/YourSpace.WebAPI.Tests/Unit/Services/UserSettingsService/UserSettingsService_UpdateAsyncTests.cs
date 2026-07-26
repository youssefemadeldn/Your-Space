using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Services.Services.UserSettingsService.Dtos;
using UserSettingsServiceImpl = YourSpace.Services.Services.UserSettingsService.UserSettingsService;

namespace YourSpace.WebAPI.Tests.Unit.Services.UserSettingsService;

public class UserSettingsService_UpdateAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<UserSettings, string>> _settingsRepo = new();

    public UserSettingsService_UpdateAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<UserSettings, string>()).Returns(_settingsRepo.Object);
    }

    private UserSettingsServiceImpl CreateSut() => new(_unitOfWork.Object, Mock.Of<ILogger<UserSettingsServiceImpl>>());

    [Fact]
    public async Task Creates_then_updates_when_no_settings_row_exists_yet()
    {
        _settingsRepo.Setup(r => r.GetByIdAsync("user-1")).ReturnsAsync((UserSettings?)null);

        var result = await CreateSut().UpdateAsync("user-1", new UpdateUserSettingsDto { ReciprocitySuggestionsEnabled = true });

        result.Success.Should().BeTrue();
        result.Data!.ReciprocitySuggestionsEnabled.Should().BeTrue();
        _settingsRepo.Verify(r => r.AddAsync(It.IsAny<UserSettings>()), Times.Once);
        _settingsRepo.Verify(r => r.Update(It.Is<UserSettings>(s => s.ReciprocitySuggestionsEnabled)), Times.Once);
    }

    [Fact]
    public async Task Toggles_existing_settings()
    {
        var existing = new UserSettings { UserId = "user-1", ReciprocitySuggestionsEnabled = false };
        _settingsRepo.Setup(r => r.GetByIdAsync("user-1")).ReturnsAsync(existing);

        var result = await CreateSut().UpdateAsync("user-1", new UpdateUserSettingsDto { ReciprocitySuggestionsEnabled = true });

        result.Success.Should().BeTrue();
        existing.ReciprocitySuggestionsEnabled.Should().BeTrue();
        _settingsRepo.Verify(r => r.AddAsync(It.IsAny<UserSettings>()), Times.Never);
    }
}
