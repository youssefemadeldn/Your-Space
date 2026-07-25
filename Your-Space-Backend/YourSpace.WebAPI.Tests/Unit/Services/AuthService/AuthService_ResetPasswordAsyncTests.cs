using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Services.Services.AuthService.Dtos;
using YourSpace.Services.Services.EmailService;
using YourSpace.Services.Services.OtpService;
using YourSpace.Services.Services.TokenService;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using FluentAssertions;
using AuthServiceImpl = YourSpace.Services.Services.AuthService.AuthService;

namespace YourSpace.WebAPI.Tests.Unit.Services.AuthService;

public class AuthService_ResetPasswordAsyncTests
{
    private readonly Mock<UserManager<AppUser>> _userManager = UserManagerMockFactory.Create();
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<RefreshToken, Guid>> _refreshTokenRepo = new();
    private readonly Mock<IOtpService> _otpService = new();

    private static readonly AppUser User = new()
    {
        Id = "user-1", Email = "jane@example.com", UserName = "jane@example.com", FirstName = "Jane", LastName = "Doe"
    };

    private static readonly ResetPasswordDto Dto = new()
    {
        Email = User.Email!,
        Code = "123456",
        NewPassword = "NewPass1!",
        ConfirmNewPassword = "NewPass1!"
    };

    public AuthService_ResetPasswordAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<RefreshToken, Guid>()).Returns(_refreshTokenRepo.Object);
        _unitOfWork.Setup(u => u.BeginTransactionAsync()).ReturnsAsync(Mock.Of<IDbContextTransaction>());
        _unitOfWork.Setup(u => u.CommitAsync(It.IsAny<IDbContextTransaction>())).Returns(Task.CompletedTask);
        _unitOfWork.Setup(u => u.RollbackAsync(It.IsAny<IDbContextTransaction>())).Returns(Task.CompletedTask);
        _userManager.Setup(m => m.FindByEmailAsync(Dto.Email)).ReturnsAsync(User);
        _refreshTokenRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<RefreshToken>>()))
            .ReturnsAsync([]);
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
    public async Task Returns_generic_failure_when_account_does_not_exist()
    {
        _userManager.Setup(m => m.FindByEmailAsync("missing@example.com")).ReturnsAsync((AppUser?)null);

        var result = await CreateSut().ResetPasswordAsync(new ResetPasswordDto
        {
            Email = "missing@example.com", Code = "123456", NewPassword = "x", ConfirmNewPassword = "x"
        });

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(400);
        result.ErrorCode.Should().Be("Auth.ResetPassword.InvalidRequest");
    }

    [Fact]
    public async Task Returns_bad_request_and_commits_when_code_invalid()
    {
        _otpService.Setup(o => o.ValidatePasswordResetCodeAsync(User.Id, Dto.Code)).ReturnsAsync(OtpValidationResult.Invalid);

        var result = await CreateSut().ResetPasswordAsync(Dto);

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(400);
        result.ErrorCode.Should().Be("Otp.Invalid");
        _unitOfWork.Verify(u => u.CommitAsync(It.IsAny<IDbContextTransaction>()), Times.Once);
        _unitOfWork.Verify(u => u.RollbackAsync(It.IsAny<IDbContextTransaction>()), Times.Never);
    }

    [Fact]
    public async Task Returns_locked_status_when_max_attempts_reached()
    {
        _otpService.Setup(o => o.ValidatePasswordResetCodeAsync(User.Id, Dto.Code)).ReturnsAsync(OtpValidationResult.LockedOut);

        var result = await CreateSut().ResetPasswordAsync(Dto);

        result.StatusCode.Should().Be(423);
        result.ErrorCode.Should().Be("Otp.LockedOut");
    }

    [Fact]
    public async Task Returns_validation_error_when_identity_reset_fails_after_a_valid_code()
    {
        _otpService.Setup(o => o.ValidatePasswordResetCodeAsync(User.Id, Dto.Code)).ReturnsAsync(OtpValidationResult.Success);
        _userManager.Setup(m => m.GeneratePasswordResetTokenAsync(User)).ReturnsAsync("identity-token");
        _userManager.Setup(m => m.ResetPasswordAsync(User, "identity-token", Dto.NewPassword))
            .ReturnsAsync(IdentityResult.Failed(new IdentityError { Code = "PasswordTooShort", Description = "Too short." }));

        var result = await CreateSut().ResetPasswordAsync(Dto);

        result.StatusCode.Should().Be(422);
        _unitOfWork.Verify(u => u.RollbackAsync(It.IsAny<IDbContextTransaction>()), Times.Once);
    }

    [Fact]
    public async Task Revokes_active_sessions_on_success()
    {
        _otpService.Setup(o => o.ValidatePasswordResetCodeAsync(User.Id, Dto.Code)).ReturnsAsync(OtpValidationResult.Success);
        _userManager.Setup(m => m.GeneratePasswordResetTokenAsync(User)).ReturnsAsync("identity-token");
        _userManager.Setup(m => m.ResetPasswordAsync(User, "identity-token", Dto.NewPassword)).ReturnsAsync(IdentityResult.Success);
        var activeToken = new RefreshToken
        {
            Id = Guid.NewGuid(), UserId = User.Id, TokenHash = "hash", ExpiresAt = DateTime.UtcNow.AddDays(1), User = User
        };
        _refreshTokenRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<RefreshToken>>()))
            .ReturnsAsync([activeToken]);

        var result = await CreateSut().ResetPasswordAsync(Dto);

        result.Success.Should().BeTrue();
        activeToken.RevokedAt.Should().NotBeNull();
        _unitOfWork.Verify(u => u.CommitAsync(It.IsAny<IDbContextTransaction>()), Times.Once);
    }
}
