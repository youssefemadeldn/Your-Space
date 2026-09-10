using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Services.Services.EmailService;
using YourSpace.Services.Services.OtpService;
using YourSpace.Services.Services.StorageService;
using YourSpace.Services.Services.TokenService;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using FluentAssertions;
using AuthServiceImpl = YourSpace.Services.Services.AuthService.AuthService;

namespace YourSpace.WebAPI.Tests.Unit.Services.AuthService;

public class AuthService_RemoveAvatarAsyncTests
{
    private readonly Mock<UserManager<AppUser>> _userManager = UserManagerMockFactory.Create();
    private readonly Mock<IR2StorageService> _r2Storage = new();

    // Instance (not static) field — RemoveAvatarAsync mutates this in place, and xUnit gives each
    // [Fact] its own class instance, so a static field here would leak state across tests.
    private readonly AppUser User = new()
    {
        Id = "user-1", Email = "jane@example.com", UserName = "jane@example.com",
        FirstName = "Jane", LastName = "Doe", Gender = Gender.Female, AvatarObjectKey = "avatars/user-1/current.jpg"
    };

    public AuthService_RemoveAvatarAsyncTests()
    {
        _userManager.Setup(m => m.FindByIdAsync(User.Id)).ReturnsAsync(User);
        _userManager.Setup(m => m.UpdateAsync(User)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.GetRolesAsync(User)).ReturnsAsync(["User"]);
    }

    private AuthServiceImpl CreateSut() => new(
        _userManager.Object,
        Mock.Of<IUnitOfWork>(),
        Mock.Of<ITokenService>(),
        Mock.Of<IOtpService>(),
        Mock.Of<IEmailSender>(),
        _r2Storage.Object,
        Options.Create(new R2Settings { AccountId = "test", AccessKey = "test", SecretKey = "test", AvatarsBucketName = "avatars", PeoplePhotosBucketName = "people" }),
        new ConfigurationBuilder().Build(),
        Mock.Of<ILogger<AuthServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_user_missing()
    {
        _userManager.Setup(m => m.FindByIdAsync("missing")).ReturnsAsync((AppUser?)null);

        var result = await CreateSut().RemoveAvatarAsync("missing");

        result.StatusCode.Should().Be(404);
        result.ErrorCode.Should().Be("Auth.User.NotFound");
    }

    [Fact]
    public async Task Removing_an_existing_avatar_deletes_the_object_and_clears_the_key()
    {
        var result = await CreateSut().RemoveAvatarAsync(User.Id);

        result.Success.Should().BeTrue();
        User.AvatarObjectKey.Should().BeNull();
        result.Data!.AvatarUrl.Should().BeNull();
        _r2Storage.Verify(s => s.DeleteAsync("avatars", "avatars/user-1/current.jpg", It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task Removing_when_no_avatar_is_set_is_an_idempotent_no_op()
    {
        User.AvatarObjectKey = null;

        var result = await CreateSut().RemoveAvatarAsync(User.Id);

        result.Success.Should().BeTrue();
        _r2Storage.Verify(s => s.DeleteAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()), Times.Never);
        _userManager.Verify(m => m.UpdateAsync(It.IsAny<AppUser>()), Times.Never);
    }
}
