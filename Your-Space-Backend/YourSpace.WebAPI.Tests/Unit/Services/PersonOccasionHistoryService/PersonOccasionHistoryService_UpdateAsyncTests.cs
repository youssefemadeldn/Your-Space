using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Services.Services.PersonOccasionHistoryService.Dtos;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using PersonOccasionHistoryServiceImpl = YourSpace.Services.Services.PersonOccasionHistoryService.PersonOccasionHistoryService;

namespace YourSpace.WebAPI.Tests.Unit.Services.PersonOccasionHistoryService;

public class PersonOccasionHistoryService_UpdateAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<PersonOccasionHistory, int>> _historyRepo = new();

    public PersonOccasionHistoryService_UpdateAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<PersonOccasionHistory, int>()).Returns(_historyRepo.Object);
    }

    private PersonOccasionHistoryServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<PersonOccasionHistoryServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_entry_does_not_exist()
    {
        _historyRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<PersonOccasionHistory>>())).ReturnsAsync((PersonOccasionHistory?)null);

        var result = await CreateSut().UpdateAsync("owner-1", personId: 10, new UpdatePersonOccasionHistoryDto { Id = 99 });

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("PersonOccasionHistory.NotFound");
    }

    [Fact]
    public async Task Clears_invite_method_when_invited_me_is_explicitly_set_to_false()
    {
        // Existing row was InvitedMe=true with a method — the caller now corrects it to false.
        var entry = new PersonOccasionHistory { Id = 1, PersonId = 10, InvitedMe = true, InviteMethod = InviteMethod.WhatsApp };
        _historyRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<PersonOccasionHistory>>())).ReturnsAsync(entry);

        var result = await CreateSut().UpdateAsync("owner-1", personId: 10, new UpdatePersonOccasionHistoryDto { Id = 1, InvitedMe = false });

        result.Success.Should().BeTrue();
        entry.InviteMethod.Should().BeNull();
    }

    [Fact]
    public async Task Keeps_invite_method_null_when_invited_me_was_already_false_and_only_notes_change()
    {
        // InvitedMe is omitted from this request (stays at its existing value: false) — the
        // validator alone can't see this, only the service resolving against the merged state can.
        var entry = new PersonOccasionHistory { Id = 1, PersonId = 10, InvitedMe = false, InviteMethod = null };
        _historyRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<PersonOccasionHistory>>())).ReturnsAsync(entry);

        var result = await CreateSut().UpdateAsync("owner-1", personId: 10, new UpdatePersonOccasionHistoryDto { Id = 1, Notes = "Confirmed with the family" });

        result.Success.Should().BeTrue();
        entry.InviteMethod.Should().BeNull();
        entry.Notes.Should().Be("Confirmed with the family");
    }

    [Fact]
    public async Task Applies_new_invite_method_when_invited_me_resolves_true()
    {
        var entry = new PersonOccasionHistory { Id = 1, PersonId = 10, InvitedMe = true, InviteMethod = InviteMethod.WhatsApp };
        _historyRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<PersonOccasionHistory>>())).ReturnsAsync(entry);

        var result = await CreateSut().UpdateAsync("owner-1", personId: 10, new UpdatePersonOccasionHistoryDto { Id = 1, InviteMethod = InviteMethod.PhoneCall });

        result.Success.Should().BeTrue();
        entry.InviteMethod.Should().Be(InviteMethod.PhoneCall);
    }
}
