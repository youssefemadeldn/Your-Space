using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Services.Services.EmailService;
using YourSpace.Services.Services.OtpService;
using YourSpace.Services.Services.TokenService;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using FluentAssertions;
using AuthServiceImpl = YourSpace.Services.Services.AuthService.AuthService;

namespace YourSpace.WebAPI.Tests.Unit.Services.AuthService;

public class AuthService_RevokeTokenAsyncTests
{
    private readonly Mock<UserManager<AppUser>> _userManager = UserManagerMockFactory.Create();
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<RefreshToken, Guid>> _refreshTokenRepo = new();
    private readonly Mock<ITokenService> _tokenService = new();

    public AuthService_RevokeTokenAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<RefreshToken, Guid>()).Returns(_refreshTokenRepo.Object);
        _tokenService.Setup(t => t.HashToken(It.IsAny<string>())).Returns<string>(raw => $"hash-of-{raw}");
    }

    private AuthServiceImpl CreateSut() => new(
        _userManager.Object,
        _unitOfWork.Object,
        _tokenService.Object,
        Mock.Of<IOtpService>(),
        Mock.Of<IEmailSender>(),
        new ConfigurationBuilder().Build(),
        Mock.Of<ILogger<AuthServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_token_unknown()
    {
        _refreshTokenRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<RefreshToken>>()))
            .ReturnsAsync((RefreshToken?)null);

        var result = await CreateSut().RevokeTokenAsync("unknown", "127.0.0.1");

        result.StatusCode.Should().Be(404);
        result.ErrorCode.Should().Be("Auth.RefreshToken.NotFound");
    }

    [Fact]
    public async Task Revokes_the_presented_token_only()
    {
        var token = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = "user-1",
            TokenHash = "hash-of-token",
            ExpiresAt = DateTime.UtcNow.AddDays(1),
            User = new AppUser { Id = "user-1", Email = "a@b.com", UserName = "a@b.com", FirstName = "A", LastName = "B" }
        };
        _refreshTokenRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<RefreshToken>>()))
            .ReturnsAsync(token);

        var result = await CreateSut().RevokeTokenAsync("token", "127.0.0.1");

        result.Success.Should().BeTrue();
        token.RevokedAt.Should().NotBeNull();
        token.ReplacedByTokenHash.Should().BeNull("logout revokes without rotating — it must not look like a reuse-of-superseded-token event");
        _refreshTokenRepo.Verify(r => r.Update(It.Is<RefreshToken>(rt => rt.Id == token.Id)), Times.Once);
    }

    [Fact]
    public async Task Is_idempotent_when_token_already_revoked()
    {
        var token = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = "user-1",
            TokenHash = "hash-of-token",
            RevokedAt = DateTime.UtcNow.AddMinutes(-5),
            ExpiresAt = DateTime.UtcNow.AddDays(1),
            User = new AppUser { Id = "user-1", Email = "a@b.com", UserName = "a@b.com", FirstName = "A", LastName = "B" }
        };
        _refreshTokenRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<RefreshToken>>()))
            .ReturnsAsync(token);

        var result = await CreateSut().RevokeTokenAsync("token", "127.0.0.1");

        result.Success.Should().BeTrue();
        _refreshTokenRepo.Verify(r => r.Update(It.IsAny<RefreshToken>()), Times.Never);
    }
}
