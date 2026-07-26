using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using EventServiceImpl = YourSpace.Services.Services.EventService.EventService;

namespace YourSpace.WebAPI.Tests.Unit.Services.EventService;

public class EventService_DeleteAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Event, int>> _eventRepo = new();

    public EventService_DeleteAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Event, int>()).Returns(_eventRepo.Object);
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

        var result = await CreateSut().DeleteAsync("owner-1", 99);

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("Event.NotFound");
    }

    [Fact]
    public async Task Soft_deletes_event_instead_of_removing_the_row()
    {
        var @event = new Event { Id = 1, OwnerUserId = "owner-1", Name = "Brother's Wedding" };
        _eventRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Event>>())).ReturnsAsync(@event);

        var result = await CreateSut().DeleteAsync("owner-1", 1);

        result.Success.Should().BeTrue();
        @event.DeletedAt.Should().NotBeNull();
        _eventRepo.Verify(r => r.Update(@event), Times.Once);
        _eventRepo.Verify(r => r.Delete(It.IsAny<Event>()), Times.Never);
    }
}
