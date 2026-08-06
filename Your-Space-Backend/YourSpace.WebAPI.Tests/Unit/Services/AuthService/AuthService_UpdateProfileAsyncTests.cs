using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Services.Services.AuthService.Dtos;
using YourSpace.Services.Services.EmailService;
using YourSpace.Services.Services.OtpService;
using YourSpace.Services.Services.TokenService;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using FluentAssertions;
using AuthServiceImpl = YourSpace.Services.Services.AuthService.AuthService;

namespace YourSpace.WebAPI.Tests.Unit.Services.AuthService;

public class AuthService_UpdateProfileAsyncTests
{
    private readonly Mock<UserManager<AppUser>> _userManager = UserManagerMockFactory.Create();

    // Instance (not static) field — UpdateProfileAsync mutates this in place, and xUnit gives
    // each [Fact] its own class instance, so a static field here would leak state across tests.
    private readonly AppUser User = new()
    {
        Id = "user-1",
        Email = "jane@example.com",
        UserName = "jane@example.com",
        FirstName = "Jane",
        LastName = "Doe",
        PhoneNumber = "+201234567890",
        Gender = Gender.Female
    };

    private static readonly UpdateProfileDto Dto = new()
    {
        FirstName = "Janet",
        LastName = "Smith",
        PhoneNumber = "+201111111111"
    };

    public AuthService_UpdateProfileAsyncTests()
    {
        _userManager.Setup(m => m.FindByIdAsync(User.Id)).ReturnsAsync(User);
    }

    private AuthServiceImpl CreateSut() => new(
        _userManager.Object,
        Mock.Of<IUnitOfWork>(),
        Mock.Of<ITokenService>(),
        Mock.Of<IOtpService>(),
        Mock.Of<IEmailSender>(),
        new ConfigurationBuilder().Build(),
        Mock.Of<ILogger<AuthServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_user_missing()
    {
        _userManager.Setup(m => m.FindByIdAsync("missing")).ReturnsAsync((AppUser?)null);

        var result = await CreateSut().UpdateProfileAsync("missing", Dto);

        result.StatusCode.Should().Be(404);
        result.ErrorCode.Should().Be("Auth.User.NotFound");
    }

    [Fact]
    public async Task Updates_and_persists_the_three_editable_fields_on_success()
    {
        _userManager.Setup(m => m.UpdateAsync(User)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.GetRolesAsync(User)).ReturnsAsync(["User"]);

        var result = await CreateSut().UpdateProfileAsync(User.Id, Dto);

        result.Success.Should().BeTrue();
        User.FirstName.Should().Be("Janet");
        User.LastName.Should().Be("Smith");
        User.PhoneNumber.Should().Be("+201111111111");
        result.Data!.FirstName.Should().Be("Janet");
        _userManager.Verify(m => m.UpdateAsync(User), Times.Once);
    }

    [Fact]
    public async Task Returns_validation_error_when_identity_update_fails()
    {
        _userManager.Setup(m => m.UpdateAsync(User))
            .ReturnsAsync(IdentityResult.Failed(new IdentityError { Code = "InvalidPhoneNumber", Description = "Phone number is invalid." }));

        var result = await CreateSut().UpdateProfileAsync(User.Id, Dto);

        result.StatusCode.Should().Be(422);
        result.Errors.Should().ContainKey("InvalidPhoneNumber");
    }
}
