using Microsoft.EntityFrameworkCore.Storage;
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

public class OtpService_GenerateAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<EmailConfirmationCode, Guid>> _emailCodeRepo = new();
    private readonly Mock<IGenericRepository<PasswordResetCode, Guid>> _resetCodeRepo = new();
    private readonly Mock<ITokenService> _tokenService = new();

    public OtpService_GenerateAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<EmailConfirmationCode, Guid>()).Returns(_emailCodeRepo.Object);
        _unitOfWork.Setup(u => u.Repository<PasswordResetCode, Guid>()).Returns(_resetCodeRepo.Object);
        _unitOfWork.Setup(u => u.BeginTransactionAsync()).ReturnsAsync(Mock.Of<IDbContextTransaction>());
        _unitOfWork.Setup(u => u.CommitAsync(It.IsAny<IDbContextTransaction>())).Returns(Task.CompletedTask);
        _unitOfWork.Setup(u => u.SaveChangesAsync()).ReturnsAsync(1);
        _tokenService.Setup(t => t.GenerateOtpCode(OtpConstants.CodeLength)).Returns("123456");
        _tokenService.Setup(t => t.HashToken(It.IsAny<string>())).Returns<string>(raw => $"hash-of-{raw}");
    }

    private OtpServiceImpl CreateSut() => new(_unitOfWork.Object, _tokenService.Object, Mock.Of<ILogger<OtpServiceImpl>>());

    [Fact]
    public async Task GenerateEmailConfirmationCodeAsync_invalidates_prior_active_codes()
    {
        var stale = new EmailConfirmationCode
        {
            Id = Guid.NewGuid(), UserId = "user-1", CodeHash = "old-hash",
            CreatedAt = DateTime.UtcNow.AddMinutes(-5), ExpiresAt = DateTime.UtcNow.AddMinutes(5)
        };
        _emailCodeRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<EmailConfirmationCode>>()))
            .ReturnsAsync([stale]);

        await CreateSut().GenerateEmailConfirmationCodeAsync("user-1");

        stale.ConsumedAt.Should().NotBeNull();
        _emailCodeRepo.Verify(r => r.Update(stale), Times.Once);
    }

    [Fact]
    public async Task GenerateEmailConfirmationCodeAsync_persists_new_hashed_code_with_expiry_and_zero_attempts()
    {
        _emailCodeRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<EmailConfirmationCode>>()))
            .ReturnsAsync([]);
        EmailConfirmationCode? added = null;
        _emailCodeRepo.Setup(r => r.AddAsync(It.IsAny<EmailConfirmationCode>()))
            .Callback<EmailConfirmationCode>(c => added = c)
            .ReturnsAsync((EmailConfirmationCode c) => c);

        var before = DateTime.UtcNow;
        await CreateSut().GenerateEmailConfirmationCodeAsync("user-1");

        added.Should().NotBeNull();
        added!.UserId.Should().Be("user-1");
        added.CodeHash.Should().Be("hash-of-123456");
        added.CodeHash.Should().NotBe("123456");
        added.AttemptCount.Should().Be(0);
        added.ConsumedAt.Should().BeNull();
        added.ExpiresAt.Should().BeCloseTo(before.AddMinutes(OtpConstants.ExpiryMinutes), TimeSpan.FromSeconds(5));
    }

    [Fact]
    public async Task GenerateEmailConfirmationCodeAsync_returns_the_raw_unhashed_code()
    {
        _emailCodeRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<EmailConfirmationCode>>()))
            .ReturnsAsync([]);

        var rawCode = await CreateSut().GenerateEmailConfirmationCodeAsync("user-1");

        rawCode.Should().Be("123456");
    }

    [Fact]
    public async Task GeneratePasswordResetCodeAsync_invalidates_prior_active_codes_and_persists_new_one()
    {
        var stale = new PasswordResetCode
        {
            Id = Guid.NewGuid(), UserId = "user-1", CodeHash = "old-hash",
            CreatedAt = DateTime.UtcNow.AddMinutes(-5), ExpiresAt = DateTime.UtcNow.AddMinutes(5)
        };
        _resetCodeRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<PasswordResetCode>>()))
            .ReturnsAsync([stale]);
        PasswordResetCode? added = null;
        _resetCodeRepo.Setup(r => r.AddAsync(It.IsAny<PasswordResetCode>()))
            .Callback<PasswordResetCode>(c => added = c)
            .ReturnsAsync((PasswordResetCode c) => c);

        var rawCode = await CreateSut().GeneratePasswordResetCodeAsync("user-1");

        stale.ConsumedAt.Should().NotBeNull();
        added.Should().NotBeNull();
        added!.CodeHash.Should().Be("hash-of-123456");
        rawCode.Should().Be("123456");
    }
}
