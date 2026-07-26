using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using EventServiceImpl = YourSpace.Services.Services.EventService.EventService;

namespace YourSpace.WebAPI.Tests.Unit.Services.EventService;

public class EventService_GetAllAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Event, int>> _eventRepo = new();
    private readonly Mock<IGenericRepository<EventGuest, int>> _guestRepo = new();

    public EventService_GetAllAsyncTests()
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
    public async Task Computes_each_events_guest_count_via_a_single_batched_query_not_one_per_event()
    {
        var events = new List<Event>
        {
            new() { Id = 1, OwnerUserId = "owner-1", Name = "Brother's Wedding" },
            new() { Id = 2, OwnerUserId = "owner-1", Name = "Cousin's Engagement" }
        };
        _eventRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Event>>())).ReturnsAsync(2);
        _eventRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Event>>())).ReturnsAsync(events);

        _guestRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<EventGuest>>())).ReturnsAsync([
            new EventGuest { Id = 1, EventId = 1, PersonId = 1 },
            new EventGuest { Id = 2, EventId = 1, PersonId = 2 },
            new EventGuest { Id = 3, EventId = 2, PersonId = 3 }
        ]);

        var result = await CreateSut().GetAllAsync("owner-1", null, new PaginationSpecification());

        result.Data!.Items.Single(e => e.Id == 1).TotalGuestCount.Should().Be(2);
        result.Data.Items.Single(e => e.Id == 2).TotalGuestCount.Should().Be(1);
        // The N+1 fix: exactly one guest query for the whole page, regardless of event count.
        _guestRepo.Verify(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<EventGuest>>()), Times.Once);
        _guestRepo.Verify(r => r.CountWithSpecAsync(It.IsAny<ISpecification<EventGuest>>()), Times.Never);
    }

    [Fact]
    public async Task Skips_the_guest_query_entirely_when_there_are_no_events()
    {
        _eventRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Event>>())).ReturnsAsync(0);
        _eventRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Event>>())).ReturnsAsync([]);

        var result = await CreateSut().GetAllAsync("owner-1", null, new PaginationSpecification());

        result.Data!.Items.Should().BeEmpty();
        _guestRepo.Verify(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<EventGuest>>()), Times.Never);
    }
}
