using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using EventGuestServiceImpl = YourSpace.Services.Services.EventGuestService.EventGuestService;

namespace YourSpace.WebAPI.Tests.Unit.Services.EventGuestService;

public class EventGuestService_GetListAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Event, int>> _eventRepo = new();
    private readonly Mock<IGenericRepository<EventGuest, int>> _guestRepo = new();

    public EventGuestService_GetListAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Event, int>()).Returns(_eventRepo.Object);
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

        var result = await CreateSut().GetListAsync("owner-1", eventId: 99, groupId: null, status: null, new PaginationSpecification());

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("EventGuest.EventNotFound");
        _guestRepo.Verify(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<EventGuest>>()), Times.Never);
    }

    [Fact]
    public async Task Returns_paginated_guest_rows_when_event_exists()
    {
        _eventRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Event>>()))
            .ReturnsAsync(new Event { Id = 1, OwnerUserId = "owner-1", Name = "Brother's Wedding" });

        var group = new Group { Id = 1, OwnerUserId = "owner-1", Name = "Relatives" };
        var person = new Person { Id = 10, OwnerUserId = "owner-1", Name = "Ahmed", GroupId = 1, Group = group };
        _guestRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<EventGuest>>())).ReturnsAsync(1);
        _guestRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<EventGuest>>()))
            .ReturnsAsync([new EventGuest { Id = 1, EventId = 1, PersonId = 10, Person = person }]);

        var result = await CreateSut().GetListAsync("owner-1", eventId: 1, groupId: null, status: null, new PaginationSpecification());

        result.Success.Should().BeTrue();
        result.Data!.Items.Should().ContainSingle(g => g.PersonName == "Ahmed");
    }
}
