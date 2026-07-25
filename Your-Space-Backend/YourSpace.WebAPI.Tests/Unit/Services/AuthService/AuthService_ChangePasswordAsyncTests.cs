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

public class AuthService_ChangePasswordAsyncTests
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
        LastName = "Doe"
    };

    private static readonly ChangePasswordDto Dto = new()
    {
        CurrentPassword = "OldPass1!",
        NewPassword = "NewPass1!",
        ConfirmNewPassword = "NewPass1!"
    };

    public AuthService_ChangePasswordAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<RefreshToken, Guid>()).Returns(_refreshTokenRepo.Object);
        _unitOfWork.Setup(u => u.BeginTransactionAsync()).ReturnsAsync(Mock.Of<IDbContextTransaction>());
        _unitOfWork.Setup(u => u.CommitAsync(It.IsAny<IDbContextTransaction>())).Returns(Task.CompletedTask);
        _userManager.Setup(m => m.FindByIdAsync(User.Id)).ReturnsAsync(User);
    }

    private AuthServiceImpl CreateSut() => new(
        _userManager.Object,
        _unitOfWork.Object,
        _tokenService.Object,
        Mock.Of<IOtpService>(),
        _emailSender.Object,
        _configuration,
        Mock.Of<ILogger<AuthServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_user_missing()
    {
        _userManager.Setup(m => m.FindByIdAsync("missing")).ReturnsAsync((AppUser?)null);

        var result = await CreateSut().ChangePasswordAsync("missing", Dto);

        result.StatusCode.Should().Be(404);
    }

    [Fact]
    public async Task Returns_validation_error_when_current_password_wrong()
    {
        _userManager.Setup(m => m.ChangePasswordAsync(User, Dto.CurrentPassword, Dto.NewPassword))
            .ReturnsAsync(IdentityResult.Failed(new IdentityError { Code = "PasswordMismatch", Description = "Incorrect password." }));

        var result = await CreateSut().ChangePasswordAsync(User.Id, Dto);

        result.StatusCode.Should().Be(422);
        result.Errors.Should().ContainKey("PasswordMismatch");
    }

    [Fact]
    public async Task Revokes_active_sessions_on_success()
    {
        _userManager.Setup(m => m.ChangePasswordAsync(User, Dto.CurrentPassword, Dto.NewPassword))
            .ReturnsAsync(IdentityResult.Success);
        var activeToken = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = User.Id,
            TokenHash = "hash",
            ExpiresAt = DateTime.UtcNow.AddDays(1),
            User = User
        };
        _refreshTokenRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<RefreshToken>>()))
            .ReturnsAsync([activeToken]);

        var result = await CreateSut().ChangePasswordAsync(User.Id, Dto);

        result.Success.Should().BeTrue();
        activeToken.RevokedAt.Should().NotBeNull();
        _refreshTokenRepo.Verify(r => r.Update(It.Is<RefreshToken>(rt => rt.Id == activeToken.Id)), Times.Once);
    }
}
