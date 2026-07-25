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

public class AuthService_RegisterAsyncTests
{
    private readonly Mock<UserManager<AppUser>> _userManager = UserManagerMockFactory.Create();
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<ITokenService> _tokenService = new();
    private readonly Mock<IEmailSender> _emailSender = new();
    private readonly IConfiguration _configuration = new ConfigurationBuilder().Build();

    private AuthServiceImpl CreateSut() => new(
        _userManager.Object,
        _unitOfWork.Object,
        _tokenService.Object,
        _emailSender.Object,
        _configuration,
        Mock.Of<ILogger<AuthServiceImpl>>());

    private static RegisterDto ValidDto() => new()
    {
        Email = "new.user@example.com",
        Password = "Str0ng!Pass",
        ConfirmPassword = "Str0ng!Pass",
        FirstName = "Jane",
        LastName = "Doe",
        PhoneNumber = "+201234567890"
    };

    [Fact]
    public async Task Returns_conflict_when_email_already_registered()
    {
        var dto = ValidDto();
        _userManager.Setup(m => m.FindByEmailAsync(dto.Email)).ReturnsAsync(new AppUser
        {
            Email = dto.Email,
            UserName = dto.Email,
            FirstName = "Existing",
            LastName = "User"
        });

        var result = await CreateSut().RegisterAsync(dto);

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(409);
        _userManager.Verify(m => m.CreateAsync(It.IsAny<AppUser>(), It.IsAny<string>()), Times.Never);
    }

    [Fact]
    public async Task Returns_validation_error_when_identity_rejects_creation()
    {
        var dto = ValidDto();
        _userManager.Setup(m => m.FindByEmailAsync(dto.Email)).ReturnsAsync((AppUser?)null);
        _userManager.Setup(m => m.CreateAsync(It.IsAny<AppUser>(), dto.Password))
            .ReturnsAsync(IdentityResult.Failed(new IdentityError { Code = "PasswordTooShort", Description = "Too short" }));

        var result = await CreateSut().RegisterAsync(dto);

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(422);
        result.Errors.Should().ContainKey("PasswordTooShort");
    }

    [Fact]
    public async Task Creates_user_assigns_role_and_sends_confirmation_email_on_success()
    {
        var dto = ValidDto();
        _userManager.Setup(m => m.FindByEmailAsync(dto.Email)).ReturnsAsync((AppUser?)null);
        _userManager.Setup(m => m.CreateAsync(It.IsAny<AppUser>(), dto.Password))
            .ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.AddToRoleAsync(It.IsAny<AppUser>(), "User"))
            .ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.GenerateEmailConfirmationTokenAsync(It.IsAny<AppUser>()))
            .ReturnsAsync("confirmation-token");
        _userManager.Setup(m => m.GetRolesAsync(It.IsAny<AppUser>()))
            .ReturnsAsync(["User"]);

        var result = await CreateSut().RegisterAsync(dto);

        result.Success.Should().BeTrue();
        result.StatusCode.Should().Be(201);
        result.Data!.Roles.Should().Contain("User");
        _userManager.Verify(m => m.AddToRoleAsync(It.IsAny<AppUser>(), "User"), Times.Once);
        _emailSender.Verify(e => e.SendEmailAsync(dto.Email, It.IsAny<string>(), It.IsAny<string>()), Times.Once);
    }

    [Fact]
    public async Task Registration_still_succeeds_when_confirmation_email_fails_to_send()
    {
        var dto = ValidDto();
        _userManager.Setup(m => m.FindByEmailAsync(dto.Email)).ReturnsAsync((AppUser?)null);
        _userManager.Setup(m => m.CreateAsync(It.IsAny<AppUser>(), dto.Password))
            .ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.AddToRoleAsync(It.IsAny<AppUser>(), "User"))
            .ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.GenerateEmailConfirmationTokenAsync(It.IsAny<AppUser>()))
            .ReturnsAsync("confirmation-token");
        _userManager.Setup(m => m.GetRolesAsync(It.IsAny<AppUser>())).ReturnsAsync(["User"]);
        _emailSender.Setup(e => e.SendEmailAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<string>()))
            .ThrowsAsync(new InvalidOperationException("SMTP unreachable"));

        var result = await CreateSut().RegisterAsync(dto);

        result.Success.Should().BeTrue("a best-effort email failure must not roll back a completed registration");
    }
}
