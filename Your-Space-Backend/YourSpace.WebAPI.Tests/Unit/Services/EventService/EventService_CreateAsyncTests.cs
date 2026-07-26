using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Services.Services.EventService.Dtos;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using EventServiceImpl = YourSpace.Services.Services.EventService.EventService;

namespace YourSpace.WebAPI.Tests.Unit.Services.EventService;

public class EventService_CreateAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Event, int>> _eventRepo = new();

    public EventService_CreateAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Event, int>()).Returns(_eventRepo.Object);
    }

    private EventServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<EventServiceImpl>>());

    [Fact]
    public async Task Creates_event_scoped_to_owner_with_zero_guest_counts()
    {
        var result = await CreateSut().CreateAsync("owner-1", new CreateEventDto { Name = "Brother's Wedding" });

        result.Success.Should().BeTrue();
        result.StatusCode.Should().Be(201);
        result.Data!.TotalGuestCount.Should().Be(0);
        result.Data.NotInvitedCount.Should().Be(0);
        _eventRepo.Verify(r => r.AddAsync(It.Is<Event>(e => e.OwnerUserId == "owner-1" && e.Name == "Brother's Wedding")), Times.Once);
    }
}
