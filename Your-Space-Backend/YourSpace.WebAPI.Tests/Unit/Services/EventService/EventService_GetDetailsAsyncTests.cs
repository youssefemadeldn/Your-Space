using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using EventServiceImpl = YourSpace.Services.Services.EventService.EventService;

namespace YourSpace.WebAPI.Tests.Unit.Services.EventService;

public class EventService_GetDetailsAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Event, int>> _eventRepo = new();
    private readonly Mock<IGenericRepository<EventGuest, int>> _guestRepo = new();

    public EventService_GetDetailsAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Event, int>()).Returns(_eventRepo.Object);
        _unitOfWork.Setup(u => u.Repository<EventGuest, int>()).Returns(_guestRepo.Object);
    }

    private EventServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<EventServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_event_does_not_exist_for_owner()
    {
        _eventRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Event>>())).ReturnsAsync((Event?)null);

        var result = await CreateSut().GetDetailsAsync("owner-1", 99);

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("Event.NotFound");
    }

    [Fact]
    public async Task Breaks_down_guest_counts_by_status()
    {
        var @event = new Event { Id = 1, OwnerUserId = "owner-1", Name = "Brother's Wedding" };
        _eventRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Event>>())).ReturnsAsync(@event);
        _guestRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<EventGuest>>())).ReturnsAsync([
            new EventGuest { Id = 1, EventId = 1, PersonId = 1, Status = EventGuestStatus.Invited },
            new EventGuest { Id = 2, EventId = 1, PersonId = 2, Status = EventGuestStatus.Invited },
            new EventGuest { Id = 3, EventId = 1, PersonId = 3, Status = EventGuestStatus.NotInvited },
            new EventGuest { Id = 4, EventId = 1, PersonId = 4, Status = EventGuestStatus.Skipped }
        ]);

        var result = await CreateSut().GetDetailsAsync("owner-1", 1);

        result.Success.Should().BeTrue();
        result.Data!.TotalGuestCount.Should().Be(4);
        result.Data.InvitedCount.Should().Be(2);
        result.Data.NotInvitedCount.Should().Be(1);
        result.Data.SkippedCount.Should().Be(1);
    }
}
