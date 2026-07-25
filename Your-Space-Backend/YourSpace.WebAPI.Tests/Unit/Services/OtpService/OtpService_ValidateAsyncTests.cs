using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Services.Services.OtpService;
using YourSpace.Services.Services.TokenService;
using FluentAssertions;
using OtpServiceImpl = YourSpace.Services.Services.OtpService.OtpService;

namespace YourSpace.WebAPI.Tests.Unit.Services.OtpService;

public class OtpService_ValidateAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<EmailConfirmationCode, Guid>> _emailCodeRepo = new();
    private readonly Mock<IGenericRepository<PasswordResetCode, Guid>> _resetCodeRepo = new();
    private readonly Mock<ITokenService> _tokenService = new();

    public OtpService_ValidateAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<EmailConfirmationCode, Guid>()).Returns(_emailCodeRepo.Object);
        _unitOfWork.Setup(u => u.Repository<PasswordResetCode, Guid>()).Returns(_resetCodeRepo.Object);
        _unitOfWork.Setup(u => u.SaveChangesAsync()).ReturnsAsync(1);
        // Deterministic stand-in for SHA-256 — "correct-code" and "wrong-code" hash to different values.
        _tokenService.Setup(t => t.HashToken(It.IsAny<string>())).Returns<string>(raw => $"hash-of-{raw}");
    }

    private OtpServiceImpl CreateSut() => new(_unitOfWork.Object, _tokenService.Object, Mock.Of<ILogger<OtpServiceImpl>>());

    private static EmailConfirmationCode ActiveCode(int attemptCount = 0) => new()
    {
        Id = Guid.NewGuid(),
        UserId = "user-1",
        CodeHash = "hash-of-correct-code",
        CreatedAt = DateTime.UtcNow,
        ExpiresAt = DateTime.UtcNow.AddMinutes(OtpConstants.ExpiryMinutes),
        AttemptCount = attemptCount
    };

    [Fact]
    public async Task Returns_NotFound_when_no_active_code_exists()
    {
        _emailCodeRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<EmailConfirmationCode>>()))
            .ReturnsAsync((EmailConfirmationCode?)null);

        var result = await CreateSut().ValidateEmailConfirmationCodeAsync("user-1", "correct-code");

        result.Should().Be(OtpValidationResult.NotFound);
    }

    [Fact]
    public async Task Returns_Expired_and_does_not_increment_attempts_when_expiry_has_passed()
    {
        var expired = ActiveCode();
        expired.ExpiresAt = DateTime.UtcNow.AddMinutes(-1);
        _emailCodeRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<EmailConfirmationCode>>()))
            .ReturnsAsync(expired);

        var result = await CreateSut().ValidateEmailConfirmationCodeAsync("user-1", "correct-code");

        result.Should().Be(OtpValidationResult.Expired);
        expired.AttemptCount.Should().Be(0);
        _emailCodeRepo.Verify(r => r.Update(It.IsAny<EmailConfirmationCode>()), Times.Never);
    }

    [Fact]
    public async Task Returns_Invalid_and_increments_attempt_count_on_a_wrong_code()
    {
        var active = ActiveCode();
        _emailCodeRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<EmailConfirmationCode>>()))
            .ReturnsAsync(active);

        var result = await CreateSut().ValidateEmailConfirmationCodeAsync("user-1", "wrong-code");

        result.Should().Be(OtpValidationResult.Invalid);
        active.AttemptCount.Should().Be(1);
        active.ConsumedAt.Should().BeNull();
        _emailCodeRepo.Verify(r => r.Update(active), Times.Once);
    }

    [Fact]
    public async Task Returns_LockedOut_and_consumes_the_code_once_max_attempts_reached()
    {
        var active = ActiveCode(attemptCount: OtpConstants.MaxAttempts - 1);
        _emailCodeRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<EmailConfirmationCode>>()))
            .ReturnsAsync(active);

        var result = await CreateSut().ValidateEmailConfirmationCodeAsync("user-1", "wrong-code");

        result.Should().Be(OtpValidationResult.LockedOut);
        active.AttemptCount.Should().Be(OtpConstants.MaxAttempts);
        active.ConsumedAt.Should().NotBeNull();
    }

    [Fact]
    public async Task Returns_Success_and_consumes_the_code_on_a_correct_code()
    {
        var active = ActiveCode();
        _emailCodeRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<EmailConfirmationCode>>()))
            .ReturnsAsync(active);

        var result = await CreateSut().ValidateEmailConfirmationCodeAsync("user-1", "correct-code");

        result.Should().Be(OtpValidationResult.Success);
        active.ConsumedAt.Should().NotBeNull();
        _emailCodeRepo.Verify(r => r.Update(active), Times.Once);
    }

    [Fact]
    public async Task ValidatePasswordResetCodeAsync_returns_Success_and_consumes_the_code_on_a_correct_code()
    {
        var active = new PasswordResetCode
        {
            Id = Guid.NewGuid(),
            UserId = "user-1",
            CodeHash = "hash-of-correct-code",
            CreatedAt = DateTime.UtcNow,
            ExpiresAt = DateTime.UtcNow.AddMinutes(OtpConstants.ExpiryMinutes)
        };
        _resetCodeRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<PasswordResetCode>>()))
            .ReturnsAsync(active);

        var result = await CreateSut().ValidatePasswordResetCodeAsync("user-1", "correct-code");

        result.Should().Be(OtpValidationResult.Success);
        active.ConsumedAt.Should().NotBeNull();
    }
}
