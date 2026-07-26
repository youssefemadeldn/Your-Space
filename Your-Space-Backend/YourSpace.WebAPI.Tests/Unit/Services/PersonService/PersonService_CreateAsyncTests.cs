using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Services.Services.PersonService.Dtos;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using PersonServiceImpl = YourSpace.Services.Services.PersonService.PersonService;

namespace YourSpace.WebAPI.Tests.Unit.Services.PersonService;

public class PersonService_CreateAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();
    private readonly Mock<IGenericRepository<Group, int>> _groupRepo = new();

    public PersonService_CreateAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Person, int>()).Returns(_personRepo.Object);
        _unitOfWork.Setup(u => u.Repository<Group, int>()).Returns(_groupRepo.Object);
    }

    private PersonServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<PersonServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_group_does_not_belong_to_owner()
    {
        _groupRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Group>>())).ReturnsAsync((Group?)null);

        var result = await CreateSut().CreateAsync("owner-1", new CreatePersonDto { Name = "Ahmed", GroupId = 7 });

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("Person.GroupNotFound");
        _personRepo.Verify(r => r.AddAsync(It.IsAny<Person>()), Times.Never);
    }

    [Fact]
    public async Task Creates_person_with_empty_history_when_group_is_valid()
    {
        var group = new Group { Id = 7, OwnerUserId = "owner-1", Name = "Village Friends" };
        _groupRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Group>>())).ReturnsAsync(group);

        var result = await CreateSut().CreateAsync("owner-1", new CreatePersonDto { Name = "Ahmed", PhoneNumber = "+201234567890", GroupId = 7 });

        result.Success.Should().BeTrue();
        result.Data!.HasReciprocityHistory.Should().BeFalse();
        result.Data.OccasionHistory.Should().BeEmpty();
        result.Data.GroupName.Should().Be("Village Friends");
        _personRepo.Verify(r => r.AddAsync(It.Is<Person>(p => p.OwnerUserId == "owner-1" && p.GroupId == 7)), Times.Once);
    }
}
