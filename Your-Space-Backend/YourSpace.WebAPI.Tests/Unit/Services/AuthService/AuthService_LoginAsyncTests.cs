using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Services.Services.AuthService.Dtos;
using YourSpace.Services.Services.EmailService;
using YourSpace.Services.Services.OtpService;
using YourSpace.Services.Services.StorageService;
using YourSpace.Services.Services.TokenService;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using FluentAssertions;
using AuthServiceImpl = YourSpace.Services.Services.AuthService.AuthService;

namespace YourSpace.WebAPI.Tests.Unit.Services.AuthService;

public class AuthService_LoginAsyncTests
{
    private readonly Mock<UserManager<AppUser>> _userManager = UserManagerMockFactory.Create();
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<RefreshToken, Guid>> _refreshTokenRepo = new();
    private readonly Mock<ITokenService> _tokenService = new();
    private readonly Mock<IEmailSender> _emailSender = new();
    private readonly IConfiguration _configuration = new ConfigurationBuilder().Build();

    private static readonly LoginDto Dto = new() { Email = "jane@example.com", Password = "Str0ng!Pass" };

    public AuthService_LoginAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<RefreshToken, Guid>()).Returns(_refreshTokenRepo.Object);
    }

    private AuthServiceImpl CreateSut() => new(
        _userManager.Object,
        _unitOfWork.Object,
        _tokenService.Object,
        Mock.Of<IOtpService>(),
        _emailSender.Object,
        Mock.Of<IR2StorageService>(),
        Options.Create(new R2Settings { AccountId = "test", AccessKey = "test", SecretKey = "test", AvatarsBucketName = "avatars", PeoplePhotosBucketName = "people" }),
        _configuration,
        Mock.Of<ILogger<AuthServiceImpl>>());

    private static AppUser SampleUser() => new()
    {
        Id = "user-1",
        Email = Dto.Email,
        UserName = Dto.Email,
        FirstName = "Jane",
        LastName = "Doe",
        Gender = Gender.Female
    };

    [Fact]
    public async Task Returns_generic_unauthorized_when_email_unknown()
    {
        _userManager.Setup(m => m.FindByEmailAsync(Dto.Email)).ReturnsAsync((AppUser?)null);

        var result = await CreateSut().LoginAsync(Dto, "127.0.0.1");

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(401);
        result.Message.Should().Be("Invalid email or password.");
        result.ErrorCode.Should().Be("Auth.InvalidCredentials");
    }

    [Fact]
    public async Task Returns_locked_status_when_account_locked_out()
    {
        var user = SampleUser();
        _userManager.Setup(m => m.FindByEmailAsync(Dto.Email)).ReturnsAsync(user);
        _userManager.Setup(m => m.IsLockedOutAsync(user)).ReturnsAsync(true);

        var result = await CreateSut().LoginAsync(Dto, "127.0.0.1");

        result.StatusCode.Should().Be(423);
        result.ErrorCode.Should().Be("Auth.AccountLocked");
    }

    [Fact]
    public async Task Records_failed_attempt_and_returns_generic_unauthorized_on_wrong_password()
    {
        var user = SampleUser();
        _userManager.Setup(m => m.FindByEmailAsync(Dto.Email)).ReturnsAsync(user);
        _userManager.Setup(m => m.IsLockedOutAsync(user)).ReturnsAsync(false);
        _userManager.Setup(m => m.CheckPasswordAsync(user, Dto.Password)).ReturnsAsync(false);

        var result = await CreateSut().LoginAsync(Dto, "127.0.0.1");

        result.StatusCode.Should().Be(401);
        result.Message.Should().Be("Invalid email or password.");
        result.ErrorCode.Should().Be("Auth.InvalidCredentials");
        _userManager.Verify(m => m.AccessFailedAsync(user), Times.Once);
    }

    [Fact]
    public async Task Blocks_login_when_email_not_confirmed()
    {
        var user = SampleUser();
        _userManager.Setup(m => m.FindByEmailAsync(Dto.Email)).ReturnsAsync(user);
        _userManager.Setup(m => m.IsLockedOutAsync(user)).ReturnsAsync(false);
        _userManager.Setup(m => m.CheckPasswordAsync(user, Dto.Password)).ReturnsAsync(true);
        _userManager.Setup(m => m.IsEmailConfirmedAsync(user)).ReturnsAsync(false);

        var result = await CreateSut().LoginAsync(Dto, "127.0.0.1");

        result.StatusCode.Should().Be(403);
        result.ErrorCode.Should().Be("Auth.EmailNotConfirmed");
    }

    [Fact]
    public async Task Issues_tokens_and_resets_failed_count_on_success()
    {
        var user = SampleUser();
        _userManager.Setup(m => m.FindByEmailAsync(Dto.Email)).ReturnsAsync(user);
        _userManager.Setup(m => m.IsLockedOutAsync(user)).ReturnsAsync(false);
        _userManager.Setup(m => m.CheckPasswordAsync(user, Dto.Password)).ReturnsAsync(true);
        _userManager.Setup(m => m.IsEmailConfirmedAsync(user)).ReturnsAsync(true);
        _userManager.Setup(m => m.GetRolesAsync(user)).ReturnsAsync(["User"]);
        _tokenService.Setup(t => t.GenerateAccessToken(user, It.IsAny<IList<string>>()))
            .Returns(("access-token", DateTime.UtcNow.AddMinutes(15)));
        _tokenService.Setup(t => t.GenerateRefreshToken()).Returns("raw-refresh-token");
        _tokenService.Setup(t => t.HashToken("raw-refresh-token")).Returns("hashed-refresh-token");

        var result = await CreateSut().LoginAsync(Dto, "127.0.0.1");

        result.Success.Should().BeTrue();
        result.Data!.AccessToken.Should().Be("access-token");
        result.Data!.RefreshToken.Should().Be("raw-refresh-token");
        _userManager.Verify(m => m.ResetAccessFailedCountAsync(user), Times.Once);
        _refreshTokenRepo.Verify(r => r.AddAsync(It.Is<RefreshToken>(rt => rt.TokenHash == "hashed-refresh-token")), Times.Once);
    }
}
