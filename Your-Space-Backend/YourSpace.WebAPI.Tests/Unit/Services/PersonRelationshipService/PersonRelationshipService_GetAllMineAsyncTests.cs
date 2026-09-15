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

public class PersonRelationshipService_GetAllMineAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Data.Entities.PersonRelationship, int>> _relationshipRepo = new();

    public PersonRelationshipService_GetAllMineAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Data.Entities.PersonRelationship, int>()).Returns(_relationshipRepo.Object);
    }

    private PersonRelationshipServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<PersonRelationshipServiceImpl>>());

    [Fact]
    public async Task Returns_every_relationship_row_across_every_person_the_owner_has_with_personId_populated()
    {
        var relatedPerson = new Person { Id = 20, OwnerUserId = "owner-1", Name = "Ahmed", Gender = Gender.Male, GroupId = 1, GovernorateId = 1 };
        var relationship = new Data.Entities.PersonRelationship
        {
            Id = 1,
            PersonId = 10,
            RelatedPersonId = 20,
            RelatedPerson = relatedPerson,
            RelationType = RelationType.Father,
            InverseRelationshipId = 2
        };
        _relationshipRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Data.Entities.PersonRelationship>>()))
            .ReturnsAsync([relationship]);

        var result = await CreateSut().GetAllMineAsync("owner-1");

        result.Success.Should().BeTrue();
        var dto = result.Data!.Single();
        dto.Id.Should().Be(1);
        dto.PersonId.Should().Be(10);
        dto.RelatedPersonId.Should().Be(20);
        dto.RelatedPersonName.Should().Be("Ahmed");
        dto.InverseRelationshipId.Should().Be(2);
    }

    [Fact]
    public async Task Returns_an_empty_list_when_the_owner_has_no_relationships()
    {
        _relationshipRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Data.Entities.PersonRelationship>>()))
            .ReturnsAsync([]);

        var result = await CreateSut().GetAllMineAsync("owner-1");

        result.Success.Should().BeTrue();
        result.Data.Should().BeEmpty();
    }
}
