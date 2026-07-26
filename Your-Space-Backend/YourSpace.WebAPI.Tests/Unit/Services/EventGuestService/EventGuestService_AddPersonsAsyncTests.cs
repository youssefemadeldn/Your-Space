using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Services.Services.EventGuestService.Dtos;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using EventGuestServiceImpl = YourSpace.Services.Services.EventGuestService.EventGuestService;

namespace YourSpace.WebAPI.Tests.Unit.Services.EventGuestService;

public class EventGuestService_AddPersonsAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Event, int>> _eventRepo = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();
    private readonly Mock<IGenericRepository<EventGuest, int>> _guestRepo = new();

    public EventGuestService_AddPersonsAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Event, int>()).Returns(_eventRepo.Object);
        _unitOfWork.Setup(u => u.Repository<Person, int>()).Returns(_personRepo.Object);
        _unitOfWork.Setup(u => u.Repository<EventGuest, int>()).Returns(_guestRepo.Object);

        _eventRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Event>>()))
            .ReturnsAsync(new Event { Id = 1, OwnerUserId = "owner-1", Name = "Brother's Wedding" });
    }

    private EventGuestServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<EventGuestServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_a_person_id_does_not_belong_to_owner()
    {
        // Only 1 of the 2 requested IDs resolves — the whole request is rejected, not partially applied.
        _personRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Person>>()))
            .ReturnsAsync([new Person { Id = 1, OwnerUserId = "owner-1", Name = "Ahmed", GroupId = 1 }]);

        var result = await CreateSut().AddPersonsAsync("owner-1", eventId: 1, new AddPersonsToEventDto { PersonIds = [1, 999] });

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("EventGuest.PersonNotFound");
        _guestRepo.Verify(r => r.AddRangeAsync(It.IsAny<List<EventGuest>>()), Times.Never);
    }

    [Fact]
    public async Task Skips_persons_already_on_the_guest_list_and_reports_both_counts()
    {
        _personRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync([
            new Person { Id = 1, OwnerUserId = "owner-1", Name = "Ahmed", GroupId = 1 },
            new Person { Id = 2, OwnerUserId = "owner-1", Name = "Sara", GroupId = 1 }
        ]);
        _guestRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<EventGuest>>()))
            .ReturnsAsync([new EventGuest { Id = 1, EventId = 1, PersonId = 1 }]); // Ahmed already added

        var result = await CreateSut().AddPersonsAsync("owner-1", eventId: 1, new AddPersonsToEventDto { PersonIds = [1, 2] });

        result.Success.Should().BeTrue();
        result.Data!.RequestedCount.Should().Be(2);
        result.Data.AddedCount.Should().Be(1);
        result.Data.AlreadyPresentCount.Should().Be(1);
        _guestRepo.Verify(r => r.AddRangeAsync(It.Is<List<EventGuest>>(list => list.Count == 1 && list[0].PersonId == 2)), Times.Once);
    }
}
