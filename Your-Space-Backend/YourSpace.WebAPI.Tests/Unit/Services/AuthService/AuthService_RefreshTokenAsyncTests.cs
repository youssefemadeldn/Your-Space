using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Services.Services.EmailService;
using YourSpace.Services.Services.OtpService;
using YourSpace.Services.Services.StorageService;
using YourSpace.Services.Services.TokenService;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using FluentAssertions;
using AuthServiceImpl = YourSpace.Services.Services.AuthService.AuthService;

namespace YourSpace.WebAPI.Tests.Unit.Services.AuthService;

public class AuthService_RefreshTokenAsyncTests
{
    private readonly Mock<UserManager<AppUser>> _userManager = UserManagerMockFactory.Create();
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<RefreshToken, Guid>> _refreshTokenRepo = new();
    private readonly Mock<ITokenService> _tokenService = new();
    private readonly Mock<IEmailSender> _emailSender = new();
    private readonly IConfiguration _configuration = new ConfigurationBuilder().Build();

    private static readonly AppUser User = new()
    {
        Id = "user-1",
        Email = "jane@example.com",
        UserName = "jane@example.com",
        FirstName = "Jane",
        LastName = "Doe",
        Gender = Gender.Female
    };

    public AuthService_RefreshTokenAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<RefreshToken, Guid>()).Returns(_refreshTokenRepo.Object);
        _unitOfWork.Setup(u => u.BeginTransactionAsync()).ReturnsAsync(Mock.Of<IDbContextTransaction>());
        _unitOfWork.Setup(u => u.CommitAsync(It.IsAny<IDbContextTransaction>())).Returns(Task.CompletedTask);
        _tokenService.Setup(t => t.HashToken(It.IsAny<string>())).Returns<string>(raw => $"hash-of-{raw}");
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

    [Fact]
    public async Task Returns_unauthorized_when_token_not_found()
    {
        _refreshTokenRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<RefreshToken>>()))
            .ReturnsAsync((RefreshToken?)null);

        var result = await CreateSut().RefreshTokenAsync("unknown-token", "127.0.0.1");

        result.StatusCode.Should().Be(401);
        result.ErrorCode.Should().Be("Auth.RefreshToken.Invalid");
    }

    [Fact]
    public async Task Revokes_all_active_tokens_when_a_rotated_away_token_is_replayed()
    {
        // ReplacedByTokenHash set = revoked via rotation, so a newer token already exists downstream.
        // Presenting this one again is the reuse-of-a-superseded-token signal, not just a stale client.
        var revoked = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = User.Id,
            TokenHash = "hash-of-stolen-token",
            RevokedAt = DateTime.UtcNow.AddMinutes(-1),
            ReplacedByTokenHash = "hash-of-the-token-that-superseded-it",
            ExpiresAt = DateTime.UtcNow.AddDays(1),
            User = User
        };
        _refreshTokenRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<RefreshToken>>()))
            .ReturnsAsync(revoked);

        var stillActive = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = User.Id,
            TokenHash = "hash-of-other-session",
            ExpiresAt = DateTime.UtcNow.AddDays(1),
            User = User
        };
        _refreshTokenRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<RefreshToken>>()))
            .ReturnsAsync([stillActive]);

        var result = await CreateSut().RefreshTokenAsync("stolen-token", "127.0.0.1");

        result.StatusCode.Should().Be(401);
        result.ErrorCode.Should().Be("Auth.RefreshToken.Reused");
        _refreshTokenRepo.Verify(r => r.Update(It.Is<RefreshToken>(rt => rt.Id == stillActive.Id && rt.RevokedAt != null)), Times.Once);
    }

    [Fact]
    public async Task Does_not_mass_revoke_when_a_plain_logged_out_token_is_reused()
    {
        // RevokedAt set but ReplacedByTokenHash null = revoked via logout, not rotation — no signal
        // that a newer token exists, so this must not be treated as theft (e.g. a client retry racing
        // a logout call would otherwise force-log-out every other device for nothing stolen).
        var loggedOut = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = User.Id,
            TokenHash = "hash-of-logged-out-token",
            RevokedAt = DateTime.UtcNow.AddMinutes(-1),
            ExpiresAt = DateTime.UtcNow.AddDays(1),
            User = User
        };
        _refreshTokenRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<RefreshToken>>()))
            .ReturnsAsync(loggedOut);

        var result = await CreateSut().RefreshTokenAsync("logged-out-token", "127.0.0.1");

        result.StatusCode.Should().Be(401);
        result.ErrorCode.Should().Be("Auth.RefreshToken.Revoked");
        _refreshTokenRepo.Verify(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<RefreshToken>>()), Times.Never);
        _refreshTokenRepo.Verify(r => r.Update(It.IsAny<RefreshToken>()), Times.Never);
    }

    [Fact]
    public async Task Returns_unauthorized_when_token_expired()
    {
        var expired = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = User.Id,
            TokenHash = "hash-of-expired-token",
            ExpiresAt = DateTime.UtcNow.AddDays(-1),
            User = User
        };
        _refreshTokenRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<RefreshToken>>()))
            .ReturnsAsync(expired);

        var result = await CreateSut().RefreshTokenAsync("expired-token", "127.0.0.1");

        result.StatusCode.Should().Be(401);
        result.ErrorCode.Should().Be("Auth.RefreshToken.Expired");
    }

    [Fact]
    public async Task Rotates_token_and_issues_new_pair_on_success()
    {
        var active = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = User.Id,
            TokenHash = "hash-of-valid-token",
            ExpiresAt = DateTime.UtcNow.AddDays(1),
            User = User
        };
        _refreshTokenRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<RefreshToken>>()))
            .ReturnsAsync(active);
        _userManager.Setup(m => m.GetRolesAsync(User)).ReturnsAsync(["User"]);
        _tokenService.Setup(t => t.GenerateAccessToken(User, It.IsAny<IList<string>>()))
            .Returns(("new-access-token", DateTime.UtcNow.AddMinutes(15)));
        _tokenService.Setup(t => t.GenerateRefreshToken()).Returns("new-raw-token");

        var result = await CreateSut().RefreshTokenAsync("valid-token", "127.0.0.1");

        result.Success.Should().BeTrue();
        result.Data!.AccessToken.Should().Be("new-access-token");
        result.Data!.RefreshToken.Should().Be("new-raw-token");
        active.RevokedAt.Should().NotBeNull();
        active.ReplacedByTokenHash.Should().Be("hash-of-new-raw-token");
        _refreshTokenRepo.Verify(r => r.AddAsync(It.Is<RefreshToken>(rt => rt.TokenHash == "hash-of-new-raw-token")), Times.Once);
        _unitOfWork.Verify(u => u.CommitAsync(It.IsAny<IDbContextTransaction>()), Times.Once);
    }
}
