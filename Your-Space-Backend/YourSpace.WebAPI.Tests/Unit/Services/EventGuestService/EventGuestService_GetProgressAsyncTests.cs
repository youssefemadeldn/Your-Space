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

public class EventGuestService_GetProgressAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Event, int>> _eventRepo = new();
    private readonly Mock<IGenericRepository<Group, int>> _groupRepo = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();
    private readonly Mock<IGenericRepository<EventGuest, int>> _guestRepo = new();

    public EventGuestService_GetProgressAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Event, int>()).Returns(_eventRepo.Object);
        _unitOfWork.Setup(u => u.Repository<Group, int>()).Returns(_groupRepo.Object);
        _unitOfWork.Setup(u => u.Repository<Person, int>()).Returns(_personRepo.Object);
        _unitOfWork.Setup(u => u.Repository<EventGuest, int>()).Returns(_guestRepo.Object);
    }

    private EventGuestServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<EventGuestServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_event_does_not_exist_for_owner()
    {
        _eventRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Event>>())).ReturnsAsync((Event?)null);

        var result = await CreateSut().GetProgressAsync("owner-1", eventId: 99);

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("EventGuest.EventNotFound");
    }

    [Fact]
    public async Task Includes_every_group_even_ones_with_zero_guests_added_to_this_event_yet()
    {
        _eventRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Event>>()))
            .ReturnsAsync(new Event { Id = 1, OwnerUserId = "owner-1", Name = "Brother's Wedding" });

        var relatives = new Group { Id = 1, OwnerUserId = "owner-1", Name = "Relatives" };
        var villageFriends = new Group { Id = 2, OwnerUserId = "owner-1", Name = "Village Friends" }; // never touched for this event
        _groupRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Group>>())).ReturnsAsync([relatives, villageFriends]);

        var personInRelatives = new Person { Id = 10, OwnerUserId = "owner-1", Name = "Ahmed", Gender = Gender.Male, GroupId = 1, GovernorateId = 1 };
        var personInVillageFriends = new Person { Id = 11, OwnerUserId = "owner-1", Name = "Sara", Gender = Gender.Female, GroupId = 2, GovernorateId = 1 };
        _personRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync([personInRelatives, personInVillageFriends]);

        // Only "Relatives" has an actual guest row added to this event so far.
        _guestRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<EventGuest>>())).ReturnsAsync([
            new EventGuest { Id = 1, EventId = 1, PersonId = 10, Person = personInRelatives, Status = EventGuestStatus.Invited }
        ]);

        var result = await CreateSut().GetProgressAsync("owner-1", eventId: 1);

        result.Success.Should().BeTrue();
        result.Data!.Groups.Should().HaveCount(2, "both groups must appear even though one has zero guests added yet");

        var relativesProgress = result.Data.Groups.Single(g => g.GroupId == 1);
        relativesProgress.TotalPersonsInGroup.Should().Be(1);
        relativesProgress.GuestsAddedCount.Should().Be(1);
        relativesProgress.InvitedCount.Should().Be(1);

        var villageFriendsProgress = result.Data.Groups.Single(g => g.GroupId == 2);
        villageFriendsProgress.TotalPersonsInGroup.Should().Be(1);
        villageFriendsProgress.GuestsAddedCount.Should().Be(0, "haven't started this group yet — distinct from 'finished'");
    }
}
