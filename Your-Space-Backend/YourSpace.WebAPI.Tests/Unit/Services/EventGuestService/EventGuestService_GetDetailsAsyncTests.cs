using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using EventGuestServiceImpl = YourSpace.Services.Services.EventGuestService.EventGuestService;

namespace YourSpace.WebAPI.Tests.Unit.Services.EventGuestService;

public class EventGuestService_GetDetailsAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<EventGuest, int>> _guestRepo = new();

    public EventGuestService_GetDetailsAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<EventGuest, int>()).Returns(_guestRepo.Object);
    }

    private EventGuestServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<EventGuestServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_guest_does_not_belong_to_the_specified_event_or_owner()
    {
        _guestRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<EventGuest>>())).ReturnsAsync((EventGuest?)null);

        var result = await CreateSut().GetDetailsAsync("owner-1", eventId: 1, guestId: 99);

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("EventGuest.NotFound");
    }

    [Fact]
    public async Task Returns_guest_details_including_resolved_group_name()
    {
        var group = new Group { Id = 1, OwnerUserId = "owner-1", Name = "Relatives" };
        var person = new Person { Id = 10, OwnerUserId = "owner-1", Name = "Ahmed", PhoneNumber = "+201234567890", GroupId = 1, Group = group };
        var guest = new EventGuest { Id = 1, EventId = 1, PersonId = 10, Person = person };
        _guestRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<EventGuest>>())).ReturnsAsync(guest);

        var result = await CreateSut().GetDetailsAsync("owner-1", eventId: 1, guestId: 1);

        result.Success.Should().BeTrue();
        result.Data!.PersonName.Should().Be("Ahmed");
        result.Data.GroupName.Should().Be("Relatives");
    }
}
