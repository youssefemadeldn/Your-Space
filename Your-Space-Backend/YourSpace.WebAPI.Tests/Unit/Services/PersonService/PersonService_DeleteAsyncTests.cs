using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using PersonServiceImpl = YourSpace.Services.Services.PersonService.PersonService;

namespace YourSpace.WebAPI.Tests.Unit.Services.PersonService;

public class PersonService_DeleteAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();

    public PersonService_DeleteAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Person, int>()).Returns(_personRepo.Object);
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

        var result = await CreateSut().DeleteAsync("owner-1", 99);

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("Person.NotFound");
    }

    [Fact]
    public async Task Soft_deletes_person_instead_of_removing_the_row()
    {
        var group = new Group { Id = 1, OwnerUserId = "owner-1", Name = "Relatives" };
        var person = new Person { Id = 10, OwnerUserId = "owner-1", Name = "Ahmed", GroupId = 1, Group = group };
        _personRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync(person);

        var result = await CreateSut().DeleteAsync("owner-1", 10);

        result.Success.Should().BeTrue();
        person.DeletedAt.Should().NotBeNull();
        _personRepo.Verify(r => r.Update(person), Times.Once);
        _personRepo.Verify(r => r.Delete(It.IsAny<Person>()), Times.Never);
    }
}
