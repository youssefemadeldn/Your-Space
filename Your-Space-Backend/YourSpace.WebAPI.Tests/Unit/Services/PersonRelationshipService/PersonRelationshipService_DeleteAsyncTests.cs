using FluentAssertions;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using PersonRelationshipServiceImpl = YourSpace.Services.Services.PersonRelationshipService.PersonRelationshipService;

namespace YourSpace.WebAPI.Tests.Unit.Services.PersonRelationshipService;

public class PersonRelationshipService_DeleteAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Data.Entities.PersonRelationship, int>> _relationshipRepo = new();

    public PersonRelationshipService_DeleteAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Data.Entities.PersonRelationship, int>()).Returns(_relationshipRepo.Object);
        _unitOfWork.Setup(u => u.BeginTransactionAsync()).ReturnsAsync(Mock.Of<IDbContextTransaction>());
        _unitOfWork.Setup(u => u.CommitAsync(It.IsAny<IDbContextTransaction>())).Returns(Task.CompletedTask);
        _unitOfWork.Setup(u => u.RollbackAsync(It.IsAny<IDbContextTransaction>())).Returns(Task.CompletedTask);
    }

    private PersonRelationshipServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<PersonRelationshipServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_relationship_does_not_exist_for_person_and_owner()
    {
        _relationshipRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Data.Entities.PersonRelationship>>()))
            .ReturnsAsync((Data.Entities.PersonRelationship?)null);

        var result = await CreateSut().DeleteAsync("owner-1", 1, 999);

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("PersonRelationship.NotFound");
    }

    [Fact]
    public async Task Cascade_deletes_the_linked_inverse_row_when_present()
    {
        var relationship = new Data.Entities.PersonRelationship
        {
            Id = 100, PersonId = 10, RelatedPersonId = 20, RelationType = RelationType.Father, InverseRelationshipId = 101
        };
        var inverse = new Data.Entities.PersonRelationship
        {
            Id = 101, PersonId = 20, RelatedPersonId = 10, RelationType = RelationType.Son, InverseRelationshipId = 100
        };
        _relationshipRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Data.Entities.PersonRelationship>>()))
            .ReturnsAsync(relationship);
        _relationshipRepo.Setup(r => r.GetByIdAsync(101)).ReturnsAsync(inverse);

        var result = await CreateSut().DeleteAsync("owner-1", 10, 100);

        result.Success.Should().BeTrue();
        _relationshipRepo.Verify(r => r.Delete(relationship), Times.Once);
        _relationshipRepo.Verify(r => r.Delete(inverse), Times.Once);
        _unitOfWork.Verify(u => u.CommitAsync(It.IsAny<IDbContextTransaction>()), Times.Once);
    }

    [Fact]
    public async Task Deletes_only_the_target_row_when_no_inverse_is_linked()
    {
        var relationship = new Data.Entities.PersonRelationship
        {
            Id = 100, PersonId = 10, RelatedPersonId = 20, RelationType = RelationType.Husband, InverseRelationshipId = null
        };
        _relationshipRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Data.Entities.PersonRelationship>>()))
            .ReturnsAsync(relationship);

        var result = await CreateSut().DeleteAsync("owner-1", 10, 100);

        result.Success.Should().BeTrue();
        _relationshipRepo.Verify(r => r.Delete(relationship), Times.Once);
        _relationshipRepo.Verify(r => r.GetByIdAsync(It.IsAny<int>()), Times.Never);
    }
}
