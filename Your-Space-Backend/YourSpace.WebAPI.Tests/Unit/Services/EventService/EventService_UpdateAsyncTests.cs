using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Services.Services.EventService.Dtos;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using EventServiceImpl = YourSpace.Services.Services.EventService.EventService;

namespace YourSpace.WebAPI.Tests.Unit.Services.EventService;

public class EventService_UpdateAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Event, int>> _eventRepo = new();
    private readonly Mock<IGenericRepository<EventGuest, int>> _guestRepo = new();

    public EventService_UpdateAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Event, int>()).Returns(_eventRepo.Object);
        _unitOfWork.Setup(u => u.Repository<EventGuest, int>()).Returns(_guestRepo.Object);
        _guestRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<EventGuest>>())).ReturnsAsync([]);
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

        var result = await CreateSut().UpdateAsync("owner-1", new UpdateEventDto { Id = 99, Name = "New Name" });

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("Event.NotFound");
    }

    [Fact]
    public async Task Leaves_notes_unchanged_when_omitted_from_request()
    {
        var @event = new Event { Id = 1, OwnerUserId = "owner-1", Name = "Brother's Wedding", Notes = "Village hall" };
        _eventRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Event>>())).ReturnsAsync(@event);

        var result = await CreateSut().UpdateAsync("owner-1", new UpdateEventDto { Id = 1, Name = "Brother's Wedding (Updated)" });

        result.Success.Should().BeTrue();
        @event.Name.Should().Be("Brother's Wedding (Updated)");
        @event.Notes.Should().Be("Village hall");
    }
}
