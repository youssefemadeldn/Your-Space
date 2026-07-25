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

    private static readonly AppUser User = new()
    {
        Id = "user-1", Email = "jane@example.com", UserName = "jane@example.com", FirstName = "Jane", LastName = "Doe"
    };

    private static readonly ResetPasswordDto Dto = new()
    {
        Email = User.Email!,
        Token = "reset-token",
        NewPassword = "NewPass1!",
        ConfirmNewPassword = "NewPass1!"
    };

    public AuthService_ResetPasswordAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<RefreshToken, Guid>()).Returns(_refreshTokenRepo.Object);
        _unitOfWork.Setup(u => u.BeginTransactionAsync()).ReturnsAsync(Mock.Of<IDbContextTransaction>());
        _unitOfWork.Setup(u => u.CommitAsync(It.IsAny<IDbContextTransaction>())).Returns(Task.CompletedTask);
    }

    private AuthServiceImpl CreateSut() => new(
        _userManager.Object,
        _unitOfWork.Object,
        Mock.Of<ITokenService>(),
        Mock.Of<IEmailSender>(),
        new ConfigurationBuilder().Build(),
        Mock.Of<ILogger<AuthServiceImpl>>());

    [Fact]
    public async Task Returns_generic_failure_when_account_does_not_exist()
    {
        _userManager.Setup(m => m.FindByEmailAsync(Dto.Email)).ReturnsAsync((AppUser?)null);

        var result = await CreateSut().ResetPasswordAsync(Dto);

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(400);
    }

    [Fact]
    public async Task Returns_validation_error_when_token_invalid()
    {
        _userManager.Setup(m => m.FindByEmailAsync(Dto.Email)).ReturnsAsync(User);
        _userManager.Setup(m => m.ResetPasswordAsync(User, Dto.Token, Dto.NewPassword))
            .ReturnsAsync(IdentityResult.Failed(new IdentityError { Code = "InvalidToken", Description = "Invalid token." }));

        var result = await CreateSut().ResetPasswordAsync(Dto);

        result.StatusCode.Should().Be(422);
    }

    [Fact]
    public async Task Revokes_active_sessions_on_success()
    {
        _userManager.Setup(m => m.FindByEmailAsync(Dto.Email)).ReturnsAsync(User);
        _userManager.Setup(m => m.ResetPasswordAsync(User, Dto.Token, Dto.NewPassword)).ReturnsAsync(IdentityResult.Success);
        var activeToken = new RefreshToken
        {
            Id = Guid.NewGuid(), UserId = User.Id, TokenHash = "hash", ExpiresAt = DateTime.UtcNow.AddDays(1), User = User
        };
        _refreshTokenRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<RefreshToken>>()))
            .ReturnsAsync([activeToken]);

        var result = await CreateSut().ResetPasswordAsync(Dto);

        result.Success.Should().BeTrue();
        activeToken.RevokedAt.Should().NotBeNull();
    }
}
