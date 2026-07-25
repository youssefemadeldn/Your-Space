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

public class AuthService_ResendConfirmationEmailAsyncTests
{
    private readonly Mock<UserManager<AppUser>> _userManager = UserManagerMockFactory.Create();
    private readonly Mock<IEmailSender> _emailSender = new();

    private AuthServiceImpl CreateSut() => new(
        _userManager.Object,
        Mock.Of<IUnitOfWork>(),
        Mock.Of<ITokenService>(),
        _emailSender.Object,
        new ConfigurationBuilder().Build(),
        Mock.Of<ILogger<AuthServiceImpl>>());

    [Fact]
    public async Task Returns_same_generic_message_whether_or_not_email_exists()
    {
        _userManager.Setup(m => m.FindByEmailAsync("unknown@example.com")).ReturnsAsync((AppUser?)null);

        var result = await CreateSut().ResendConfirmationEmailAsync(new ResendConfirmationEmailDto { Email = "unknown@example.com" });

        result.Success.Should().BeTrue();
        result.StatusCode.Should().Be(200);
    }

    [Fact]
    public async Task Does_not_send_when_email_already_confirmed()
    {
        var user = new AppUser { Id = "user-1", Email = "a@b.com", UserName = "a@b.com", FirstName = "A", LastName = "B" };
        _userManager.Setup(m => m.FindByEmailAsync("a@b.com")).ReturnsAsync(user);
        _userManager.Setup(m => m.IsEmailConfirmedAsync(user)).ReturnsAsync(true);

        await CreateSut().ResendConfirmationEmailAsync(new ResendConfirmationEmailDto { Email = "a@b.com" });

        _emailSender.Verify(e => e.SendEmailAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<string>()), Times.Never);
    }

    [Fact]
    public async Task Sends_new_token_when_unconfirmed_account_exists()
    {
        var user = new AppUser { Id = "user-1", Email = "a@b.com", UserName = "a@b.com", FirstName = "A", LastName = "B" };
        _userManager.Setup(m => m.FindByEmailAsync("a@b.com")).ReturnsAsync(user);
        _userManager.Setup(m => m.IsEmailConfirmedAsync(user)).ReturnsAsync(false);
        _userManager.Setup(m => m.GenerateEmailConfirmationTokenAsync(user)).ReturnsAsync("new-token");

        await CreateSut().ResendConfirmationEmailAsync(new ResendConfirmationEmailDto { Email = "a@b.com" });

        _emailSender.Verify(e => e.SendEmailAsync("a@b.com", It.IsAny<string>(), It.Is<string>(body => body.Contains("new-token"))), Times.Once);
    }
}
