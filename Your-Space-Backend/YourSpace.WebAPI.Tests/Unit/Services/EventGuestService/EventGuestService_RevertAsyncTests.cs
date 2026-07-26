using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using EventGuestServiceImpl = YourSpace.Services.Services.EventGuestService.EventGuestService;

namespace YourSpace.WebAPI.Tests.Unit.Services.EventGuestService;

public class EventGuestService_RevertAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<EventGuest, int>> _guestRepo = new();

    public EventGuestService_RevertAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<EventGuest, int>()).Returns(_guestRepo.Object);
    }

    private EventGuestServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<EventGuestServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_guest_does_not_exist()
    {
        _guestRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<EventGuest>>())).ReturnsAsync((EventGuest?)null);

        var result = await CreateSut().RevertAsync("owner-1", eventId: 1, guestId: 99);

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("EventGuest.NotFound");
    }

    [Fact]
    public async Task Resets_an_invited_guest_back_to_not_invited()
    {
        var group = new Group { Id = 1, OwnerUserId = "owner-1", Name = "Relatives" };
        var person = new Person { Id = 10, OwnerUserId = "owner-1", Name = "Ahmed", GroupId = 1, Group = group };
        var guest = new EventGuest
        {
            Id = 1, EventId = 1, PersonId = 10, Person = person,
            Status = EventGuestStatus.Invited, InviteMethod = InviteMethod.WhatsApp, InvitedAt = DateTime.UtcNow
        };
        _guestRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<EventGuest>>())).ReturnsAsync(guest);

        var result = await CreateSut().RevertAsync("owner-1", eventId: 1, guestId: 1);

        result.Success.Should().BeTrue();
        guest.Status.Should().Be(EventGuestStatus.NotInvited);
        guest.InviteMethod.Should().BeNull();
        guest.InvitedAt.Should().BeNull();
    }

    [Fact]
    public async Task Reverting_an_already_not_invited_guest_is_a_harmless_no_op()
    {
        var group = new Group { Id = 1, OwnerUserId = "owner-1", Name = "Relatives" };
        var person = new Person { Id = 10, OwnerUserId = "owner-1", Name = "Ahmed", GroupId = 1, Group = group };
        var guest = new EventGuest { Id = 1, EventId = 1, PersonId = 10, Person = person, Status = EventGuestStatus.NotInvited };
        _guestRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<EventGuest>>())).ReturnsAsync(guest);

        var result = await CreateSut().RevertAsync("owner-1", eventId: 1, guestId: 1);

        result.Success.Should().BeTrue();
        guest.Status.Should().Be(EventGuestStatus.NotInvited);
    }
}
