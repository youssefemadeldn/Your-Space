using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Services.Services.AuthService.Dtos;
using YourSpace.Services.Services.EmailService;
using YourSpace.Services.Services.TokenService;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using FluentAssertions;
using AuthServiceImpl = YourSpace.Services.Services.AuthService.AuthService;

namespace YourSpace.WebAPI.Tests.Unit.Services.AuthService;

public class AuthService_ConfirmEmailAsyncTests
{
    private readonly Mock<UserManager<AppUser>> _userManager = UserManagerMockFactory.Create();

    private AuthServiceImpl CreateSut() => new(
        _userManager.Object,
        Mock.Of<IUnitOfWork>(),
        Mock.Of<ITokenService>(),
        Mock.Of<IEmailSender>(),
        new ConfigurationBuilder().Build(),
        Mock.Of<ILogger<AuthServiceImpl>>());

    [Fact]
    public async Task Returns_bad_request_when_user_id_invalid()
    {
        _userManager.Setup(m => m.FindByIdAsync("missing")).ReturnsAsync((AppUser?)null);

        var result = await CreateSut().ConfirmEmailAsync(new ConfirmEmailDto { UserId = "missing", Token = "t" });

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(400);
    }

    [Fact]
    public async Task Returns_bad_request_when_token_invalid()
    {
        var user = new AppUser { Id = "user-1", Email = "a@b.com", UserName = "a@b.com", FirstName = "A", LastName = "B" };
        _userManager.Setup(m => m.FindByIdAsync("user-1")).ReturnsAsync(user);
        _userManager.Setup(m => m.ConfirmEmailAsync(user, "bad-token"))
            .ReturnsAsync(IdentityResult.Failed(new IdentityError { Code = "InvalidToken", Description = "Invalid token." }));

        var result = await CreateSut().ConfirmEmailAsync(new ConfirmEmailDto { UserId = "user-1", Token = "bad-token" });

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(400);
    }

    [Fact]
    public async Task Confirms_email_on_valid_token()
    {
        var user = new AppUser { Id = "user-1", Email = "a@b.com", UserName = "a@b.com", FirstName = "A", LastName = "B" };
        _userManager.Setup(m => m.FindByIdAsync("user-1")).ReturnsAsync(user);
        _userManager.Setup(m => m.ConfirmEmailAsync(user, "good-token")).ReturnsAsync(IdentityResult.Success);

        var result = await CreateSut().ConfirmEmailAsync(new ConfirmEmailDto { UserId = "user-1", Token = "good-token" });

        result.Success.Should().BeTrue();
    }
}
