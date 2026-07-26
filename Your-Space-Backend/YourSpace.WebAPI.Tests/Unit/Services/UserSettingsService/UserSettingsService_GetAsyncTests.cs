using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using UserSettingsServiceImpl = YourSpace.Services.Services.UserSettingsService.UserSettingsService;

namespace YourSpace.WebAPI.Tests.Unit.Services.UserSettingsService;

public class UserSettingsService_GetAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<UserSettings, string>> _settingsRepo = new();

    public UserSettingsService_GetAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<UserSettings, string>()).Returns(_settingsRepo.Object);
    }

    private UserSettingsServiceImpl CreateSut() => new(_unitOfWork.Object, Mock.Of<ILogger<UserSettingsServiceImpl>>());

    [Fact]
    public async Task Lazily_creates_default_settings_off_on_first_access()
    {
        _settingsRepo.Setup(r => r.GetByIdAsync("user-1")).ReturnsAsync((UserSettings?)null);

        var result = await CreateSut().GetAsync("user-1");

        result.Success.Should().BeTrue();
        result.Data!.UserId.Should().Be("user-1");
        result.Data.ReciprocitySuggestionsEnabled.Should().BeFalse();
        _settingsRepo.Verify(r => r.AddAsync(It.Is<UserSettings>(s => s.UserId == "user-1" && !s.ReciprocitySuggestionsEnabled)), Times.Once);
        _unitOfWork.Verify(u => u.SaveChangesAsync(), Times.Once);
    }

    [Fact]
    public async Task Returns_existing_settings_without_creating_a_new_row()
    {
        var existing = new UserSettings { UserId = "user-1", ReciprocitySuggestionsEnabled = true };
        _settingsRepo.Setup(r => r.GetByIdAsync("user-1")).ReturnsAsync(existing);

        var result = await CreateSut().GetAsync("user-1");

        result.Success.Should().BeTrue();
        result.Data!.ReciprocitySuggestionsEnabled.Should().BeTrue();
        _settingsRepo.Verify(r => r.AddAsync(It.IsAny<UserSettings>()), Times.Never);
    }
}
