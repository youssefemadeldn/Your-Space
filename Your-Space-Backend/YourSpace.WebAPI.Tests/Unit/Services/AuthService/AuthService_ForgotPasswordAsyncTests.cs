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

public class AuthService_ForgotPasswordAsyncTests
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
        _userManager.Setup(m => m.FindByEmailAsync("known@example.com")).ReturnsAsync(new AppUser
        {
            Id = "user-1", Email = "known@example.com", UserName = "known@example.com", FirstName = "A", LastName = "B"
        });

        var unknownResult = await CreateSut().ForgotPasswordAsync(new ForgotPasswordDto { Email = "unknown@example.com" });
        var knownResult = await CreateSut().ForgotPasswordAsync(new ForgotPasswordDto { Email = "known@example.com" });

        unknownResult.Message.Should().Be(knownResult.Message);
        unknownResult.StatusCode.Should().Be(knownResult.StatusCode);
    }

    [Fact]
    public async Task Only_sends_email_when_account_exists()
    {
        _userManager.Setup(m => m.FindByEmailAsync("unknown@example.com")).ReturnsAsync((AppUser?)null);

        await CreateSut().ForgotPasswordAsync(new ForgotPasswordDto { Email = "unknown@example.com" });

        _emailSender.Verify(e => e.SendEmailAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<string>()), Times.Never);
    }
}
