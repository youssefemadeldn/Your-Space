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

public class EventGuestService_GetReciprocitySuggestionsAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Event, int>> _eventRepo = new();
    private readonly Mock<IGenericRepository<PersonOccasionHistory, int>> _historyRepo = new();
    private readonly Mock<IGenericRepository<EventGuest, int>> _guestRepo = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();

    public EventGuestService_GetReciprocitySuggestionsAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Event, int>()).Returns(_eventRepo.Object);
        _unitOfWork.Setup(u => u.Repository<PersonOccasionHistory, int>()).Returns(_historyRepo.Object);
        _unitOfWork.Setup(u => u.Repository<EventGuest, int>()).Returns(_guestRepo.Object);
        _unitOfWork.Setup(u => u.Repository<Person, int>()).Returns(_personRepo.Object);

        _eventRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Event>>()))
            .ReturnsAsync(new Event { Id = 1, OwnerUserId = "owner-1", Name = "Brother's Wedding" });
    }

    private EventGuestServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<EventGuestServiceImpl>>());

    [Fact]
    public async Task Excludes_persons_already_added_to_this_event()
    {
        // Both Person 1 and Person 2 invited the user before, but Person 1 is already on this
        // event's guest list — only Person 2 should come back as a suggestion.
        _historyRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<PersonOccasionHistory>>())).ReturnsAsync([
            new PersonOccasionHistory { Id = 1, PersonId = 1, InvitedMe = true },
            new PersonOccasionHistory { Id = 2, PersonId = 2, InvitedMe = true }
        ]);
        _guestRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<EventGuest>>())).ReturnsAsync([
            new EventGuest { Id = 1, EventId = 1, PersonId = 1 }
        ]);

        var group = new Group { Id = 1, OwnerUserId = "owner-1", Name = "Village Friends" };
        _personRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Person>>()))
            .ReturnsAsync([new Person { Id = 2, OwnerUserId = "owner-1", Name = "Sara", GroupId = 1, Group = group }]);

        var result = await CreateSut().GetReciprocitySuggestionsAsync("owner-1", eventId: 1, groupId: null, new PaginationSpecification());

        result.Success.Should().BeTrue();
        result.Data!.Items.Should().ContainSingle(p => p.Id == 2);
        result.Data.Items.Single().HasReciprocityHistory.Should().BeTrue();
    }

    [Fact]
    public async Task Returns_empty_page_without_querying_persons_when_no_candidates_remain()
    {
        _historyRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<PersonOccasionHistory>>())).ReturnsAsync([]);
        _guestRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<EventGuest>>())).ReturnsAsync([]);

        var result = await CreateSut().GetReciprocitySuggestionsAsync("owner-1", eventId: 1, groupId: null, new PaginationSpecification());

        result.Success.Should().BeTrue();
        result.Data!.Items.Should().BeEmpty();
        _personRepo.Verify(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Person>>()), Times.Never);
    }
}
