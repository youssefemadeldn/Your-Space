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

public class AuthService_GetProfileAsyncTests
{
    private readonly Mock<UserManager<AppUser>> _userManager = UserManagerMockFactory.Create();

    private AuthServiceImpl CreateSut() => new(
        _userManager.Object,
        Mock.Of<IUnitOfWork>(),
        Mock.Of<ITokenService>(),
        Mock.Of<IOtpService>(),
        Mock.Of<IEmailSender>(),
        Mock.Of<IR2StorageService>(),
        Options.Create(new R2Settings { AccountId = "test", AccessKey = "test", SecretKey = "test", AvatarsBucketName = "avatars", PeoplePhotosBucketName = "people" }),
        new ConfigurationBuilder().Build(),
        Mock.Of<ILogger<AuthServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_user_missing()
    {
        _userManager.Setup(m => m.FindByIdAsync("missing")).ReturnsAsync((AppUser?)null);

        var result = await CreateSut().GetProfileAsync("missing");

        result.StatusCode.Should().Be(404);
        result.ErrorCode.Should().Be("Auth.User.NotFound");
    }

    [Fact]
    public async Task Returns_profile_with_roles_on_success()
    {
        var user = new AppUser
        {
            Id = "user-1", Email = "jane@example.com", UserName = "jane@example.com",
            FirstName = "Jane", LastName = "Doe", PhoneNumber = "+201234567890", Gender = Gender.Female
        };
        _userManager.Setup(m => m.FindByIdAsync("user-1")).ReturnsAsync(user);
        _userManager.Setup(m => m.GetRolesAsync(user)).ReturnsAsync(["User", "StandardAdmin"]);

        var result = await CreateSut().GetProfileAsync("user-1");

        result.Success.Should().BeTrue();
        result.Data!.Email.Should().Be("jane@example.com");
        result.Data.Roles.Should().BeEquivalentTo(["User", "StandardAdmin"]);
    }
}
