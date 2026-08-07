using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Services.Services.AuthService.Dtos;
using YourSpace.Services.Services.EmailService;
using YourSpace.Services.Services.OtpService;
using YourSpace.Services.Services.StorageService;
using YourSpace.Services.Services.TokenService;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using FluentAssertions;
using AuthServiceImpl = YourSpace.Services.Services.AuthService.AuthService;

namespace YourSpace.WebAPI.Tests.Unit.Services.AuthService;

public class AuthService_UploadAvatarAsyncTests
{
    private readonly Mock<UserManager<AppUser>> _userManager = UserManagerMockFactory.Create();
    private readonly Mock<IR2StorageService> _r2Storage = new();

    // Instance (not static) field — UploadAvatarAsync mutates this in place, and xUnit gives each
    // [Fact] its own class instance, so a static field here would leak state across tests.
    private readonly AppUser User = new()
    {
        Id = "user-1", Email = "jane@example.com", UserName = "jane@example.com",
        FirstName = "Jane", LastName = "Doe", Gender = Gender.Female
    };

    public AuthService_UploadAvatarAsyncTests()
    {
        _userManager.Setup(m => m.FindByIdAsync(User.Id)).ReturnsAsync(User);
        _userManager.Setup(m => m.UpdateAsync(User)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.GetRolesAsync(User)).ReturnsAsync(["User"]);
        _r2Storage.Setup(s => s.GetPresignedUrlAsync(It.IsAny<string>(), It.IsAny<string>())).ReturnsAsync("https://fake/url");
    }

    private AuthServiceImpl CreateSut() => new(
        _userManager.Object,
        Mock.Of<IUnitOfWork>(),
        Mock.Of<ITokenService>(),
        Mock.Of<IOtpService>(),
        Mock.Of<IEmailSender>(),
        _r2Storage.Object,
        Options.Create(new R2Settings { AccountId = "test", AccessKey = "test", SecretKey = "test", AvatarsBucketName = "avatars", PeoplePhotosBucketName = "people" }),
        new ConfigurationBuilder().Build(),
        Mock.Of<ILogger<AuthServiceImpl>>());

    private static UploadAvatarDto MakeDto()
    {
        var file = new Mock<IFormFile>();
        file.Setup(f => f.ContentType).Returns("image/jpeg");
        file.Setup(f => f.Length).Returns(1024);
        return new UploadAvatarDto { File = file.Object };
    }

    [Fact]
    public async Task Returns_not_found_when_user_missing()
    {
        _userManager.Setup(m => m.FindByIdAsync("missing")).ReturnsAsync((AppUser?)null);

        var result = await CreateSut().UploadAvatarAsync("missing", MakeDto());

        result.StatusCode.Should().Be(404);
        result.ErrorCode.Should().Be("Auth.User.NotFound");
    }

    [Fact]
    public async Task Uploads_and_sets_the_object_key_on_success()
    {
        var result = await CreateSut().UploadAvatarAsync(User.Id, MakeDto());

        result.Success.Should().BeTrue();
        User.AvatarObjectKey.Should().NotBeNullOrEmpty();
        User.AvatarObjectKey.Should().StartWith($"avatars/{User.Id}/");
        result.Data!.AvatarUrl.Should().Be("https://fake/url");
        _r2Storage.Verify(s => s.UploadAsync("avatars", It.IsAny<string>(), It.IsAny<IFormFile>(), It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task Replacing_an_existing_avatar_deletes_the_old_object()
    {
        User.AvatarObjectKey = "avatars/user-1/old.jpg";

        var result = await CreateSut().UploadAvatarAsync(User.Id, MakeDto());

        result.Success.Should().BeTrue();
        User.AvatarObjectKey.Should().NotBe("avatars/user-1/old.jpg");
        _r2Storage.Verify(s => s.DeleteAsync("avatars", "avatars/user-1/old.jpg", It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task A_failed_old_object_delete_does_not_block_the_new_upload()
    {
        User.AvatarObjectKey = "avatars/user-1/old.jpg";
        _r2Storage.Setup(s => s.DeleteAsync("avatars", "avatars/user-1/old.jpg", It.IsAny<CancellationToken>()))
            .ThrowsAsync(new InvalidOperationException("R2 unreachable"));

        var result = await CreateSut().UploadAvatarAsync(User.Id, MakeDto());

        result.Success.Should().BeTrue();
        _r2Storage.Verify(s => s.UploadAsync("avatars", It.IsAny<string>(), It.IsAny<IFormFile>(), It.IsAny<CancellationToken>()), Times.Once);
    }
}
