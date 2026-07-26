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

public class PersonService_UpdateAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();
    private readonly Mock<IGenericRepository<Group, int>> _groupRepo = new();
    private readonly Mock<IGenericRepository<PersonOccasionHistory, int>> _historyRepo = new();

    public PersonService_UpdateAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Person, int>()).Returns(_personRepo.Object);
        _unitOfWork.Setup(u => u.Repository<Group, int>()).Returns(_groupRepo.Object);
        _unitOfWork.Setup(u => u.Repository<PersonOccasionHistory, int>()).Returns(_historyRepo.Object);
        _historyRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<PersonOccasionHistory>>())).ReturnsAsync([]);
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

        var result = await CreateSut().UpdateAsync("owner-1", new UpdatePersonDto { Id = 99, Name = "New Name" });

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("Person.NotFound");
    }

    [Fact]
    public async Task Returns_not_found_when_new_group_does_not_belong_to_owner()
    {
        var originalGroup = new Group { Id = 1, OwnerUserId = "owner-1", Name = "Relatives" };
        var person = new Person { Id = 10, OwnerUserId = "owner-1", Name = "Ahmed", GroupId = 1, Group = originalGroup };
        _personRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync(person);
        _groupRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Group>>())).ReturnsAsync((Group?)null);

        var result = await CreateSut().UpdateAsync("owner-1", new UpdatePersonDto { Id = 10, GroupId = 999 });

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("Person.GroupNotFound");
        person.GroupId.Should().Be(1, "the move must not be applied when the target group is invalid");
    }

    [Fact]
    public async Task Leaves_phone_number_unchanged_when_omitted_from_request()
    {
        var group = new Group { Id = 1, OwnerUserId = "owner-1", Name = "Relatives" };
        var person = new Person { Id = 10, OwnerUserId = "owner-1", Name = "Ahmed", PhoneNumber = "+201234567890", GroupId = 1, Group = group };
        _personRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync(person);

        var result = await CreateSut().UpdateAsync("owner-1", new UpdatePersonDto { Id = 10, Name = "Ahmed Updated" });

        result.Success.Should().BeTrue();
        person.Name.Should().Be("Ahmed Updated");
        person.PhoneNumber.Should().Be("+201234567890");
    }
}
