using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using PersonServiceImpl = YourSpace.Services.Services.PersonService.PersonService;

namespace YourSpace.WebAPI.Tests.Unit.Services.PersonService;

public class PersonService_GetAllAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();
    private readonly Mock<IGenericRepository<PersonOccasionHistory, int>> _historyRepo = new();

    public PersonService_GetAllAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Person, int>()).Returns(_personRepo.Object);
        _unitOfWork.Setup(u => u.Repository<PersonOccasionHistory, int>()).Returns(_historyRepo.Object);
    }

    private PersonServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<PersonServiceImpl>>());

    [Fact]
    public async Task Flags_only_persons_with_an_invited_me_true_record_without_an_n_plus_one_per_row()
    {
        var group = new Group { Id = 1, OwnerUserId = "owner-1", Name = "Relatives" };
        var withHistory = new Person { Id = 1, OwnerUserId = "owner-1", Name = "Ahmed", Gender = Gender.Male, GroupId = 1, Group = group };
        var withoutHistory = new Person { Id = 2, OwnerUserId = "owner-1", Name = "Sara", Gender = Gender.Female, GroupId = 1, Group = group };

        _personRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync(2);
        _personRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync([withHistory, withoutHistory]);
        _historyRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<PersonOccasionHistory>>()))
            .ReturnsAsync([new PersonOccasionHistory { Id = 1, PersonId = 1, InvitedMe = true }]);

        var result = await CreateSut().GetAllAsync("owner-1", null, null, new PaginationSpecification());

        result.Data!.Items.Single(p => p.Id == 1).HasReciprocityHistory.Should().BeTrue();
        result.Data.Items.Single(p => p.Id == 2).HasReciprocityHistory.Should().BeFalse();
        // One call regardless of page size — not one lookup per person.
        _historyRepo.Verify(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<PersonOccasionHistory>>()), Times.Once);
    }
}
