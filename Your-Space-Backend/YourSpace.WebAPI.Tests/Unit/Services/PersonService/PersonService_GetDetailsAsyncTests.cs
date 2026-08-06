using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using PersonServiceImpl = YourSpace.Services.Services.PersonService.PersonService;

namespace YourSpace.WebAPI.Tests.Unit.Services.PersonService;

public class PersonService_GetDetailsAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();
    private readonly Mock<IGenericRepository<PersonOccasionHistory, int>> _historyRepo = new();

    public PersonService_GetDetailsAsyncTests()
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
    public async Task Returns_not_found_when_person_does_not_exist_for_owner()
    {
        _personRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync((Person?)null);

        var result = await CreateSut().GetDetailsAsync("owner-1", 99);

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("Person.NotFound");
    }

    [Fact]
    public async Task Sets_has_reciprocity_history_true_when_a_past_occasion_invited_the_user()
    {
        var group = new Group { Id = 1, OwnerUserId = "owner-1", Name = "Relatives" };
        var person = new Person { Id = 10, OwnerUserId = "owner-1", Name = "Ahmed", Gender = Gender.Male, GroupId = 1, Group = group };
        _personRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync(person);

        _historyRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<PersonOccasionHistory>>()))
            .ReturnsAsync([
                new PersonOccasionHistory { Id = 1, PersonId = 10, InvitedMe = false },
                new PersonOccasionHistory { Id = 2, PersonId = 10, InvitedMe = true }
            ]);

        var result = await CreateSut().GetDetailsAsync("owner-1", 10);

        result.Success.Should().BeTrue();
        result.Data!.HasReciprocityHistory.Should().BeTrue();
        result.Data.OccasionHistory.Should().HaveCount(2);
        result.Data.GroupName.Should().Be("Relatives");
    }
}
