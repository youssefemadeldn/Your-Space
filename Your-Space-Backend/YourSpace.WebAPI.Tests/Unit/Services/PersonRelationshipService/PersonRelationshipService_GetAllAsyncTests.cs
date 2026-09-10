using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using PersonRelationshipServiceImpl = YourSpace.Services.Services.PersonRelationshipService.PersonRelationshipService;

namespace YourSpace.WebAPI.Tests.Unit.Services.PersonRelationshipService;

public class PersonRelationshipService_GetAllAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();
    private readonly Mock<IGenericRepository<Data.Entities.PersonRelationship, int>> _relationshipRepo = new();

    public PersonRelationshipService_GetAllAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Person, int>()).Returns(_personRepo.Object);
        _unitOfWork.Setup(u => u.Repository<Data.Entities.PersonRelationship, int>()).Returns(_relationshipRepo.Object);
    }

    private PersonRelationshipServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<PersonRelationshipServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_person_does_not_exist_for_owner()
    {
        _personRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync((Person?)null);

        var result = await CreateSut().GetAllAsync("owner-1", 999);

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(404);
        result.ErrorCode.Should().Be("Person.NotFound");
    }

    [Fact]
    public async Task Returns_relationships_with_related_person_names()
    {
        var subject = new Person { Id = 1, OwnerUserId = "owner-1", Name = "Youssef", Gender = Gender.Male, GroupId = 1, GovernorateId = 1 };
        _personRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync(subject);

        var father = new Person { Id = 2, OwnerUserId = "owner-1", Name = "Ahmed", Gender = Gender.Male, GroupId = 1, GovernorateId = 1 };
        var relationship = new Data.Entities.PersonRelationship
        {
            Id = 10,
            PersonId = 1,
            RelatedPersonId = 2,
            RelationType = RelationType.Father,
            RelatedPerson = father
        };
        _relationshipRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Data.Entities.PersonRelationship>>()))
            .ReturnsAsync([relationship]);

        var result = await CreateSut().GetAllAsync("owner-1", 1);

        result.Success.Should().BeTrue();
        result.Data.Should().ContainSingle();
        result.Data![0].RelatedPersonId.Should().Be(2);
        result.Data[0].RelatedPersonName.Should().Be("Ahmed");
        result.Data[0].RelationType.Should().Be(RelationType.Father);
    }
}
