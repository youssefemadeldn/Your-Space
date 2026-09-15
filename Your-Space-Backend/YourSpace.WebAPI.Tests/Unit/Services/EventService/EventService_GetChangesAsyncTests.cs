using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Repository.Sync;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using EventServiceImpl = YourSpace.Services.Services.EventService.EventService;

namespace YourSpace.WebAPI.Tests.Unit.Services.EventService;

public class EventService_GetChangesAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Event, int>> _eventRepo = new();
    private readonly Mock<IGenericRepository<EventGuest, int>> _guestRepo = new();

    public EventService_GetChangesAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Event, int>()).Returns(_eventRepo.Object);
        _unitOfWork.Setup(u => u.Repository<EventGuest, int>()).Returns(_guestRepo.Object);
        _guestRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<EventGuest>>())).ReturnsAsync([]);
    }

    private EventServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ISyncVersionProvider>(),
        Mock.Of<ILogger<EventServiceImpl>>());

    private static Event Alive(int id, long syncVersion) => new()
    {
        Id = id,
        OwnerUserId = "owner-1",
        Name = $"Event {id}",
        SyncVersion = syncVersion
    };

    private static Event Deleted(int id, long syncVersion) => new()
    {
        Id = id,
        OwnerUserId = "owner-1",
        Name = $"Event {id}",
        SyncVersion = syncVersion,
        DeletedAt = DateTime.UtcNow
    };

    [Fact]
    public async Task Returns_empty_page_with_cursor_unchanged_when_nothing_has_changed()
    {
        _eventRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Event>>())).ReturnsAsync([]);

        var result = await CreateSut().GetChangesAsync("owner-1", since: 10, pageSize: 50);

        result.Success.Should().BeTrue();
        result.Data!.Upserts.Should().BeEmpty();
        result.Data.TombstoneIds.Should().BeEmpty();
        result.Data.Cursor.Should().Be(10);
        result.Data.HasMore.Should().BeFalse();
    }

    [Fact]
    public async Task Returns_upserts_only_when_every_changed_row_is_still_alive()
    {
        _eventRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Event>>()))
            .ReturnsAsync([Alive(1, 5), Alive(2, 7)]);

        var result = await CreateSut().GetChangesAsync("owner-1", since: 0, pageSize: 50);

        result.Data!.Upserts.Select(e => e.Id).Should().BeEquivalentTo([1, 2]);
        result.Data.TombstoneIds.Should().BeEmpty();
        result.Data.Cursor.Should().Be(7);
    }

    [Fact]
    public async Task Returns_tombstones_only_when_every_changed_row_is_soft_deleted()
    {
        _eventRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Event>>()))
            .ReturnsAsync([Deleted(3, 9)]);

        var result = await CreateSut().GetChangesAsync("owner-1", since: 0, pageSize: 50);

        result.Data!.Upserts.Should().BeEmpty();
        result.Data.TombstoneIds.Should().BeEquivalentTo([3]);
        result.Data.Cursor.Should().Be(9);
    }

    [Fact]
    public async Task Splits_a_mixed_page_into_upserts_and_tombstones_and_takes_the_max_syncversion_as_cursor()
    {
        _eventRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Event>>()))
            .ReturnsAsync([Alive(1, 5), Deleted(2, 11), Alive(3, 8)]);

        var result = await CreateSut().GetChangesAsync("owner-1", since: 0, pageSize: 50);

        result.Data!.Upserts.Select(e => e.Id).Should().BeEquivalentTo([1, 3]);
        result.Data.TombstoneIds.Should().BeEquivalentTo([2]);
        result.Data.Cursor.Should().Be(11);
    }

    [Fact]
    public async Task HasMore_is_true_when_the_page_returned_is_exactly_full()
    {
        _eventRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Event>>()))
            .ReturnsAsync([Alive(1, 1), Alive(2, 2)]);

        var result = await CreateSut().GetChangesAsync("owner-1", since: 0, pageSize: 2);

        result.Data!.HasMore.Should().BeTrue();
    }

    [Fact]
    public async Task HasMore_is_false_when_the_page_returned_is_under_the_requested_size()
    {
        _eventRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Event>>()))
            .ReturnsAsync([Alive(1, 1)]);

        var result = await CreateSut().GetChangesAsync("owner-1", since: 0, pageSize: 2);

        result.Data!.HasMore.Should().BeFalse();
    }

    [Fact]
    public async Task Rejects_a_negative_since_cursor()
    {
        var result = await CreateSut().GetChangesAsync("owner-1", since: -1, pageSize: 50);

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("Event.Since.Invalid");
        _eventRepo.Verify(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Event>>()), Times.Never);
    }

    [Fact]
    public async Task Upserted_rows_carry_their_batched_guest_count()
    {
        _eventRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Event>>()))
            .ReturnsAsync([Alive(1, 5)]);
        _guestRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<EventGuest>>()))
            .ReturnsAsync([
                new EventGuest { Id = 1, EventId = 1, PersonId = 1 },
                new EventGuest { Id = 2, EventId = 1, PersonId = 2 }
            ]);

        var result = await CreateSut().GetChangesAsync("owner-1", since: 0, pageSize: 50);

        result.Data!.Upserts.Single().TotalGuestCount.Should().Be(2);
    }
}
