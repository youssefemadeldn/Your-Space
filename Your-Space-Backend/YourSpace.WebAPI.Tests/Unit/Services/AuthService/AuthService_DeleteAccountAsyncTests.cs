using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
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

public class AuthService_DeleteAccountAsyncTests
{
    private readonly Mock<UserManager<AppUser>> _userManager = UserManagerMockFactory.Create();
    private readonly Mock<IUnitOfWork> _unitOfWork = new();

    private readonly Mock<IGenericRepository<EventGuest, int>> _eventGuestRepo = new();
    private readonly Mock<IGenericRepository<PersonOccasionHistory, int>> _historyRepo = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();
    private readonly Mock<IGenericRepository<Event, int>> _eventRepo = new();
    private readonly Mock<IGenericRepository<Group, int>> _groupRepo = new();
    private readonly Mock<IGenericRepository<RefreshToken, Guid>> _refreshTokenRepo = new();
    private readonly Mock<IGenericRepository<EmailConfirmationCode, Guid>> _emailCodeRepo = new();
    private readonly Mock<IGenericRepository<PasswordResetCode, Guid>> _resetCodeRepo = new();
    private readonly Mock<IGenericRepository<UserSettings, string>> _settingsRepo = new();

    // Every Delete call across every repo, in the order the service made them.
    private readonly List<string> _deleteLog = [];

    private static readonly AppUser User = new()
    {
        Id = "user-1",
        Email = "jane@example.com",
        UserName = "jane@example.com",
        FirstName = "Jane",
        LastName = "Doe"
    };

    private static readonly DeleteAccountDto Dto = new() { Password = "OldPass1!" };

    public AuthService_DeleteAccountAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<EventGuest, int>()).Returns(_eventGuestRepo.Object);
        _unitOfWork.Setup(u => u.Repository<PersonOccasionHistory, int>()).Returns(_historyRepo.Object);
        _unitOfWork.Setup(u => u.Repository<Person, int>()).Returns(_personRepo.Object);
        _unitOfWork.Setup(u => u.Repository<Event, int>()).Returns(_eventRepo.Object);
        _unitOfWork.Setup(u => u.Repository<Group, int>()).Returns(_groupRepo.Object);
        _unitOfWork.Setup(u => u.Repository<RefreshToken, Guid>()).Returns(_refreshTokenRepo.Object);
        _unitOfWork.Setup(u => u.Repository<EmailConfirmationCode, Guid>()).Returns(_emailCodeRepo.Object);
        _unitOfWork.Setup(u => u.Repository<PasswordResetCode, Guid>()).Returns(_resetCodeRepo.Object);
        _unitOfWork.Setup(u => u.Repository<UserSettings, string>()).Returns(_settingsRepo.Object);
        _unitOfWork.Setup(u => u.SaveChangesAsync()).ReturnsAsync(0);
        _unitOfWork.Setup(u => u.BeginTransactionAsync()).ReturnsAsync(Mock.Of<IDbContextTransaction>());
        _unitOfWork.Setup(u => u.CommitAsync(It.IsAny<IDbContextTransaction>())).Returns(Task.CompletedTask);
        _unitOfWork.Setup(u => u.RollbackAsync(It.IsAny<IDbContextTransaction>())).Returns(Task.CompletedTask);

        // Nothing to delete unless a test overrides the specific repo.
        _eventGuestRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<EventGuest>>())).ReturnsAsync([]);
        _historyRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<PersonOccasionHistory>>())).ReturnsAsync([]);
        _personRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync([]);
        _eventRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Event>>())).ReturnsAsync([]);
        _groupRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Group>>())).ReturnsAsync([]);
        _refreshTokenRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<RefreshToken>>())).ReturnsAsync([]);
        _emailCodeRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<EmailConfirmationCode>>())).ReturnsAsync([]);
        _resetCodeRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<PasswordResetCode>>())).ReturnsAsync([]);
        _settingsRepo.Setup(r => r.GetByIdAsync(User.Id)).ReturnsAsync((UserSettings?)null);

        _eventGuestRepo.Setup(r => r.Delete(It.IsAny<EventGuest>())).Callback(() => _deleteLog.Add("eventguest"));
        _historyRepo.Setup(r => r.Delete(It.IsAny<PersonOccasionHistory>())).Callback(() => _deleteLog.Add("history"));
        _personRepo.Setup(r => r.Delete(It.IsAny<Person>())).Callback(() => _deleteLog.Add("person"));
        _eventRepo.Setup(r => r.Delete(It.IsAny<Event>())).Callback(() => _deleteLog.Add("event"));
        _groupRepo.Setup(r => r.Delete(It.IsAny<Group>())).Callback(() => _deleteLog.Add("group"));
        _refreshTokenRepo.Setup(r => r.Delete(It.IsAny<RefreshToken>())).Callback(() => _deleteLog.Add("refreshtoken"));
        _emailCodeRepo.Setup(r => r.Delete(It.IsAny<EmailConfirmationCode>())).Callback(() => _deleteLog.Add("emailcode"));
        _resetCodeRepo.Setup(r => r.Delete(It.IsAny<PasswordResetCode>())).Callback(() => _deleteLog.Add("resetcode"));
        _settingsRepo.Setup(r => r.Delete(It.IsAny<UserSettings>())).Callback(() => _deleteLog.Add("settings"));

        _userManager.Setup(m => m.FindByIdAsync(User.Id)).ReturnsAsync(User);
        _userManager.Setup(m => m.CheckPasswordAsync(User, Dto.Password)).ReturnsAsync(true);
        _userManager.Setup(m => m.DeleteAsync(User))
            .Callback(() => _deleteLog.Add("user"))
            .ReturnsAsync(IdentityResult.Success);
    }

    private AuthServiceImpl CreateSut() => new(
        _userManager.Object,
        _unitOfWork.Object,
        Mock.Of<ITokenService>(),
        Mock.Of<IOtpService>(),
        Mock.Of<IEmailSender>(),
        new ConfigurationBuilder().Build(),
        Mock.Of<ILogger<AuthServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_user_missing()
    {
        _userManager.Setup(m => m.FindByIdAsync("missing")).ReturnsAsync((AppUser?)null);

        var result = await CreateSut().DeleteAccountAsync("missing", Dto);

        result.StatusCode.Should().Be(404);
        result.ErrorCode.Should().Be("Auth.User.NotFound");
        _unitOfWork.Verify(u => u.BeginTransactionAsync(), Times.Never);
    }

    [Fact]
    public async Task Returns_validation_error_when_password_incorrect()
    {
        _userManager.Setup(m => m.CheckPasswordAsync(User, Dto.Password)).ReturnsAsync(false);

        var result = await CreateSut().DeleteAccountAsync(User.Id, Dto);

        result.StatusCode.Should().Be(422);
        result.ErrorCode.Should().Be("Auth.DeleteAccount.InvalidPassword");
        _unitOfWork.Verify(u => u.BeginTransactionAsync(), Times.Never);
        _deleteLog.Should().BeEmpty();
        _userManager.Verify(m => m.DeleteAsync(It.IsAny<AppUser>()), Times.Never);
    }

    [Fact]
    public async Task Deletes_all_owned_data_and_the_user_on_success()
    {
        _eventGuestRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<EventGuest>>()))
            .ReturnsAsync([new EventGuest { EventId = 1, PersonId = 1 }]);
        _historyRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<PersonOccasionHistory>>()))
            .ReturnsAsync([new PersonOccasionHistory { PersonId = 1, InvitedMe = false }]);
        _personRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Person>>()))
            .ReturnsAsync([new Person { OwnerUserId = User.Id, Name = "Contact", Gender = Gender.Male, GroupId = 1 }]);
        _eventRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Event>>()))
            .ReturnsAsync([new Event { OwnerUserId = User.Id, Name = "Party" }]);
        _groupRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Group>>()))
            .ReturnsAsync([new Group { OwnerUserId = User.Id, Name = "Family" }]);
        _refreshTokenRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<RefreshToken>>()))
            .ReturnsAsync([new RefreshToken { UserId = User.Id, TokenHash = "hash", ExpiresAt = DateTime.UtcNow }]);
        _emailCodeRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<EmailConfirmationCode>>()))
            .ReturnsAsync([new EmailConfirmationCode { UserId = User.Id, CodeHash = "hash", ExpiresAt = DateTime.UtcNow }]);
        _resetCodeRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<PasswordResetCode>>()))
            .ReturnsAsync([new PasswordResetCode { UserId = User.Id, CodeHash = "hash", ExpiresAt = DateTime.UtcNow }]);
        _settingsRepo.Setup(r => r.GetByIdAsync(User.Id))
            .ReturnsAsync(new UserSettings { UserId = User.Id });

        var result = await CreateSut().DeleteAccountAsync(User.Id, Dto);

        result.Success.Should().BeTrue();
        result.StatusCode.Should().Be(200);
        _deleteLog.Should().Contain(["eventguest", "history", "person", "event", "group", "refreshtoken", "emailcode", "resetcode", "settings", "user"]);
        _userManager.Verify(m => m.DeleteAsync(User), Times.Once);
        _unitOfWork.Verify(u => u.CommitAsync(It.IsAny<IDbContextTransaction>()), Times.Once);
        _unitOfWork.Verify(u => u.RollbackAsync(It.IsAny<IDbContextTransaction>()), Times.Never);
    }

    [Fact]
    public async Task Deletes_children_before_parents_before_the_identity_row()
    {
        _eventGuestRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<EventGuest>>()))
            .ReturnsAsync([new EventGuest { EventId = 1, PersonId = 1 }]);
        _historyRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<PersonOccasionHistory>>()))
            .ReturnsAsync([new PersonOccasionHistory { PersonId = 1, InvitedMe = false }]);
        _personRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Person>>()))
            .ReturnsAsync([new Person { OwnerUserId = User.Id, Name = "Contact", Gender = Gender.Male, GroupId = 1 }]);
        _eventRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Event>>()))
            .ReturnsAsync([new Event { OwnerUserId = User.Id, Name = "Party" }]);
        _groupRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Group>>()))
            .ReturnsAsync([new Group { OwnerUserId = User.Id, Name = "Family" }]);

        await CreateSut().DeleteAccountAsync(User.Id, Dto);

        // EventGuest / PersonOccasionHistory reference Person; Person references Group. The user row
        // (with its RESTRICT-guarded People→Groups edge) goes last.
        _deleteLog.IndexOf("eventguest").Should().BeLessThan(_deleteLog.IndexOf("person"));
        _deleteLog.IndexOf("history").Should().BeLessThan(_deleteLog.IndexOf("person"));
        _deleteLog.IndexOf("person").Should().BeLessThan(_deleteLog.IndexOf("event"));
        _deleteLog.IndexOf("event").Should().BeLessThan(_deleteLog.IndexOf("group"));
        _deleteLog.IndexOf("group").Should().BeLessThan(_deleteLog.IndexOf("user"));
        _deleteLog[^1].Should().Be("user");
    }

    [Fact]
    public async Task Rolls_back_and_rethrows_when_a_delete_fails()
    {
        _unitOfWork.Setup(u => u.SaveChangesAsync()).ThrowsAsync(new InvalidOperationException("db is down"));

        var act = () => CreateSut().DeleteAccountAsync(User.Id, Dto);

        await act.Should().ThrowAsync<InvalidOperationException>();
        _unitOfWork.Verify(u => u.RollbackAsync(It.IsAny<IDbContextTransaction>()), Times.Once);
        _unitOfWork.Verify(u => u.CommitAsync(It.IsAny<IDbContextTransaction>()), Times.Never);
    }

    [Fact]
    public async Task Rolls_back_when_the_identity_delete_fails()
    {
        _userManager.Setup(m => m.DeleteAsync(User))
            .ReturnsAsync(IdentityResult.Failed(new IdentityError { Code = "ConcurrencyFailure", Description = "stale row" }));

        var result = await CreateSut().DeleteAccountAsync(User.Id, Dto);

        result.StatusCode.Should().Be(500);
        result.ErrorCode.Should().Be("Auth.DeleteAccount.Failed");
        _unitOfWork.Verify(u => u.RollbackAsync(It.IsAny<IDbContextTransaction>()), Times.Once);
        _unitOfWork.Verify(u => u.CommitAsync(It.IsAny<IDbContextTransaction>()), Times.Never);
    }
}
