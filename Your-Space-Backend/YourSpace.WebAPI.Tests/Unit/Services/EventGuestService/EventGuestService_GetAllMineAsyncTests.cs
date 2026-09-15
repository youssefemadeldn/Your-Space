using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using EventGuestServiceImpl = YourSpace.Services.Services.EventGuestService.EventGuestService;

namespace YourSpace.WebAPI.Tests.Unit.Services.EventGuestService;

public class EventGuestService_GetAllMineAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<EventGuest, int>> _guestRepo = new();

    public EventGuestService_GetAllMineAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<EventGuest, int>()).Returns(_guestRepo.Object);
    }

    private EventGuestServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<EventGuestServiceImpl>>());

    [Fact]
    public async Task Returns_every_guest_row_across_every_event_the_owner_has_with_eventId_populated()
    {
        var group = new Group { Id = 3, OwnerUserId = "owner-1", Name = "Relatives" };
        var person = new Person
        {
            Id = 5,
            OwnerUserId = "owner-1",
            Name = "Sara",
            Gender = Gender.Female,
            GroupId = 3,
            Group = group,
            GovernorateId = 1
        };
        var guest = new EventGuest { Id = 1, EventId = 7, PersonId = 5, Person = person, Status = EventGuestStatus.Invited };
        _guestRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<EventGuest>>())).ReturnsAsync([guest]);

        var result = await CreateSut().GetAllMineAsync("owner-1");

        result.Success.Should().BeTrue();
        var dto = result.Data!.Single();
        dto.Id.Should().Be(1);
        dto.EventId.Should().Be(7);
        dto.PersonId.Should().Be(5);
        dto.PersonName.Should().Be("Sara");
        dto.GroupId.Should().Be(3);
    }

    [Fact]
    public async Task Returns_an_empty_list_when_the_owner_has_no_guests()
    {
        _guestRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<EventGuest>>())).ReturnsAsync([]);

        var result = await CreateSut().GetAllMineAsync("owner-1");

        result.Success.Should().BeTrue();
        result.Data.Should().BeEmpty();
    }
}
