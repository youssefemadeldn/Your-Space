using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using EventGuestServiceImpl = YourSpace.Services.Services.EventGuestService.EventGuestService;

namespace YourSpace.WebAPI.Tests.Unit.Services.EventGuestService;

public class EventGuestService_RemoveGuestAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<EventGuest, int>> _guestRepo = new();

    public EventGuestService_RemoveGuestAsyncTests()
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

        var result = await CreateSut().RemoveGuestAsync("owner-1", eventId: 1, guestId: 99);

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("EventGuest.NotFound");
    }

    [Fact]
    public async Task Hard_deletes_the_guest_row_entirely()
    {
        var guest = new EventGuest { Id = 1, EventId = 1, PersonId = 10 };
        _guestRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<EventGuest>>())).ReturnsAsync(guest);

        var result = await CreateSut().RemoveGuestAsync("owner-1", eventId: 1, guestId: 1);

        result.Success.Should().BeTrue();
        _guestRepo.Verify(r => r.Delete(guest), Times.Once);
    }
}
