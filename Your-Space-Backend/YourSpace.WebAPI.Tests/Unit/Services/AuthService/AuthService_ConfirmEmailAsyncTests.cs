using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Services.Services.AuthService.Dtos;
using YourSpace.Services.Services.EmailService;
using YourSpace.Services.Services.OtpService;
using YourSpace.Services.Services.TokenService;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using FluentAssertions;
using AuthServiceImpl = YourSpace.Services.Services.AuthService.AuthService;

namespace YourSpace.WebAPI.Tests.Unit.Services.AuthService;

public class AuthService_ConfirmEmailAsyncTests
{
    private readonly Mock<UserManager<AppUser>> _userManager = UserManagerMockFactory.Create();
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IOtpService> _otpService = new();

    private static readonly AppUser User = new()
    {
        Id = "user-1", Email = "a@b.com", UserName = "a@b.com", FirstName = "A", LastName = "B"
    };

    private static readonly ConfirmEmailDto Dto = new() { Email = User.Email!, Code = "123456" };

    public AuthService_ConfirmEmailAsyncTests()
    {
        _unitOfWork.Setup(u => u.BeginTransactionAsync()).ReturnsAsync(Mock.Of<IDbContextTransaction>());
        _unitOfWork.Setup(u => u.CommitAsync(It.IsAny<IDbContextTransaction>())).Returns(Task.CompletedTask);
        _unitOfWork.Setup(u => u.RollbackAsync(It.IsAny<IDbContextTransaction>())).Returns(Task.CompletedTask);
        _userManager.Setup(m => m.FindByEmailAsync(User.Email!)).ReturnsAsync(User);
    }

    private AuthServiceImpl CreateSut() => new(
        _userManager.Object,
        _unitOfWork.Object,
        Mock.Of<ITokenService>(),
        _otpService.Object,
        Mock.Of<IEmailSender>(),
        new ConfigurationBuilder().Build(),
        Mock.Of<ILogger<AuthServiceImpl>>());

    [Fact]
    public async Task Returns_bad_request_when_email_unknown()
    {
        _userManager.Setup(m => m.FindByEmailAsync("missing@example.com")).ReturnsAsync((AppUser?)null);

        var result = await CreateSut().ConfirmEmailAsync(new ConfirmEmailDto { Email = "missing@example.com", Code = "123456" });

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(400);
        result.ErrorCode.Should().Be("Auth.ConfirmEmail.InvalidRequest");
        _otpService.Verify(o => o.ValidateEmailConfirmationCodeAsync(It.IsAny<string>(), It.IsAny<string>()), Times.Never);
    }

    [Fact]
    public async Task Returns_bad_request_and_commits_when_code_invalid()
    {
        _otpService.Setup(o => o.ValidateEmailConfirmationCodeAsync(User.Id, Dto.Code)).ReturnsAsync(OtpValidationResult.Invalid);

        var result = await CreateSut().ConfirmEmailAsync(Dto);

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(400);
        result.ErrorCode.Should().Be("Otp.Invalid");
        // A wrong-code attempt still records an attempt count against the OTP row — that write must
        // be kept, not rolled back, even though the overall call "fails".
        _unitOfWork.Verify(u => u.CommitAsync(It.IsAny<IDbContextTransaction>()), Times.Once);
        _unitOfWork.Verify(u => u.RollbackAsync(It.IsAny<IDbContextTransaction>()), Times.Never);
    }

    [Fact]
    public async Task Returns_bad_request_when_code_expired()
    {
        _otpService.Setup(o => o.ValidateEmailConfirmationCodeAsync(User.Id, Dto.Code)).ReturnsAsync(OtpValidationResult.Expired);

        var result = await CreateSut().ConfirmEmailAsync(Dto);

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(400);
        result.ErrorCode.Should().Be("Otp.Expired");
    }

    [Fact]
    public async Task Returns_locked_status_when_max_attempts_reached()
    {
        _otpService.Setup(o => o.ValidateEmailConfirmationCodeAsync(User.Id, Dto.Code)).ReturnsAsync(OtpValidationResult.LockedOut);

        var result = await CreateSut().ConfirmEmailAsync(Dto);

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(423);
        result.ErrorCode.Should().Be("Otp.LockedOut");
    }

    [Fact]
    public async Task Rolls_back_when_identity_confirmation_fails_after_a_valid_code()
    {
        _otpService.Setup(o => o.ValidateEmailConfirmationCodeAsync(User.Id, Dto.Code)).ReturnsAsync(OtpValidationResult.Success);
        _userManager.Setup(m => m.GenerateEmailConfirmationTokenAsync(User)).ReturnsAsync("identity-token");
        _userManager.Setup(m => m.ConfirmEmailAsync(User, "identity-token"))
            .ReturnsAsync(IdentityResult.Failed(new IdentityError { Code = "Unexpected", Description = "Unexpected." }));

        var result = await CreateSut().ConfirmEmailAsync(Dto);

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(400);
        result.ErrorCode.Should().Be("Auth.ConfirmEmail.Failed");
        _unitOfWork.Verify(u => u.RollbackAsync(It.IsAny<IDbContextTransaction>()), Times.Once);
        _unitOfWork.Verify(u => u.CommitAsync(It.IsAny<IDbContextTransaction>()), Times.Never);
    }

    [Fact]
    public async Task Confirms_email_on_valid_code()
    {
        _otpService.Setup(o => o.ValidateEmailConfirmationCodeAsync(User.Id, Dto.Code)).ReturnsAsync(OtpValidationResult.Success);
        _userManager.Setup(m => m.GenerateEmailConfirmationTokenAsync(User)).ReturnsAsync("identity-token");
        _userManager.Setup(m => m.ConfirmEmailAsync(User, "identity-token")).ReturnsAsync(IdentityResult.Success);

        var result = await CreateSut().ConfirmEmailAsync(Dto);

        result.Success.Should().BeTrue();
        _unitOfWork.Verify(u => u.CommitAsync(It.IsAny<IDbContextTransaction>()), Times.Once);
    }
}
