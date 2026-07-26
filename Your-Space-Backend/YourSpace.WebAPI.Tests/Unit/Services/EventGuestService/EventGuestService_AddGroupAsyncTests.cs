using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using EventGuestServiceImpl = YourSpace.Services.Services.EventGuestService.EventGuestService;

namespace YourSpace.WebAPI.Tests.Unit.Services.EventGuestService;

public class EventGuestService_AddGroupAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Event, int>> _eventRepo = new();
    private readonly Mock<IGenericRepository<Group, int>> _groupRepo = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();
    private readonly Mock<IGenericRepository<EventGuest, int>> _guestRepo = new();

    public EventGuestService_AddGroupAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Event, int>()).Returns(_eventRepo.Object);
        _unitOfWork.Setup(u => u.Repository<Group, int>()).Returns(_groupRepo.Object);
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
    public async Task Returns_not_found_when_group_does_not_belong_to_owner()
    {
        _groupRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Group>>())).ReturnsAsync((Group?)null);

        var result = await CreateSut().AddGroupAsync("owner-1", eventId: 1, groupId: 999);

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("EventGuest.GroupNotFound");
    }

    [Fact]
    public async Task Adds_every_active_person_in_the_group_at_once()
    {
        _groupRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Group>>()))
            .ReturnsAsync(new Group { Id = 1, OwnerUserId = "owner-1", Name = "Village Friends" });
        _personRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync([
            new Person { Id = 1, OwnerUserId = "owner-1", Name = "Ahmed", GroupId = 1 },
            new Person { Id = 2, OwnerUserId = "owner-1", Name = "Sara", GroupId = 1 }
        ]);
        _guestRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<EventGuest>>())).ReturnsAsync([]);

        var result = await CreateSut().AddGroupAsync("owner-1", eventId: 1, groupId: 1);

        result.Success.Should().BeTrue();
        result.Data!.RequestedCount.Should().Be(2);
        result.Data.AddedCount.Should().Be(2);
        _guestRepo.Verify(r => r.AddRangeAsync(It.Is<List<EventGuest>>(list => list.Count == 2)), Times.Once);
    }
}
