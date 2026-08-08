using FluentAssertions;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Services.Services.PersonRelationshipService.Dtos;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using PersonRelationshipServiceImpl = YourSpace.Services.Services.PersonRelationshipService.PersonRelationshipService;

namespace YourSpace.WebAPI.Tests.Unit.Services.PersonRelationshipService;

public class PersonRelationshipService_CreateAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();
    private readonly Mock<IGenericRepository<Data.Entities.PersonRelationship, int>> _relationshipRepo = new();
    private int _nextId = 100;

    public PersonRelationshipService_CreateAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Person, int>()).Returns(_personRepo.Object);
        _unitOfWork.Setup(u => u.Repository<Data.Entities.PersonRelationship, int>()).Returns(_relationshipRepo.Object);
        _unitOfWork.Setup(u => u.BeginTransactionAsync()).ReturnsAsync(Mock.Of<IDbContextTransaction>());
        _unitOfWork.Setup(u => u.CommitAsync(It.IsAny<IDbContextTransaction>())).Returns(Task.CompletedTask);
        _unitOfWork.Setup(u => u.RollbackAsync(It.IsAny<IDbContextTransaction>())).Returns(Task.CompletedTask);

        // Simulates the Id a real DB would assign on insert — the SUT cross-links the two rows by
        // Id after the first SaveChangesAsync, so the test needs realistic, distinct Ids too.
        _relationshipRepo.Setup(r => r.AddAsync(It.IsAny<Data.Entities.PersonRelationship>()))
            .ReturnsAsync((Data.Entities.PersonRelationship pr) =>
            {
                pr.Id = _nextId++;
                return pr;
            });
    }

    private PersonRelationshipServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<PersonRelationshipServiceImpl>>());

    private static Person MakePerson(int id, string name, Gender gender) =>
        new() { Id = id, OwnerUserId = "owner-1", Name = name, Gender = gender, GroupId = 1, GovernorateId = 1 };

    [Fact]
    public async Task Returns_conflict_when_related_person_is_the_same_person()
    {
        var result = await CreateSut().CreateAsync(
            "owner-1", 1, new CreatePersonRelationshipDto { RelatedPersonId = 1, RelationType = RelationType.Brother });

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(409);
        result.ErrorCode.Should().Be("PersonRelationship.SelfLink");
        _personRepo.Verify(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Person>>()), Times.Never);
    }

    [Fact]
    public async Task Returns_not_found_when_person_does_not_exist()
    {
        _personRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync((Person?)null);

        var result = await CreateSut().CreateAsync(
            "owner-1", 1, new CreatePersonRelationshipDto { RelatedPersonId = 2, RelationType = RelationType.Brother });

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("Person.NotFound");
    }

    [Fact]
    public async Task Returns_not_found_when_related_person_does_not_exist()
    {
        var subject = MakePerson(1, "Youssef", Gender.Male);
        _personRepo.SetupSequence(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Person>>()))
            .ReturnsAsync(subject)
            .ReturnsAsync((Person?)null);

        var result = await CreateSut().CreateAsync(
            "owner-1", 1, new CreatePersonRelationshipDto { RelatedPersonId = 999, RelationType = RelationType.Brother });

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("PersonRelationship.RelatedPersonNotFound");
    }

    [Fact]
    public async Task Returns_conflict_when_person_already_has_a_father()
    {
        var subject = MakePerson(1, "Youssef", Gender.Male);
        var relatedPerson = MakePerson(2, "Ahmed", Gender.Male);
        _personRepo.SetupSequence(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Person>>()))
            .ReturnsAsync(subject)
            .ReturnsAsync(relatedPerson);
        _relationshipRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Data.Entities.PersonRelationship>>())).ReturnsAsync(1);

        var result = await CreateSut().CreateAsync(
            "owner-1", 1, new CreatePersonRelationshipDto { RelatedPersonId = 2, RelationType = RelationType.Father });

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(409);
        result.ErrorCode.Should().Be("PersonRelationship.DuplicateParent");
        _relationshipRepo.Verify(r => r.AddAsync(It.IsAny<Data.Entities.PersonRelationship>()), Times.Never);
    }

    [Fact]
    public async Task Allows_unlimited_spouses_bypassing_the_duplicate_parent_check()
    {
        // Husband/Wife are neither ParentTypes nor ChildTypes — the duplicate-count and
        // cycle-detection guard clauses must never run for them.
        var subject = MakePerson(1, "Youssef", Gender.Male);
        var relatedPerson = MakePerson(2, "Mona", Gender.Female);
        _personRepo.SetupSequence(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Person>>()))
            .ReturnsAsync(subject)
            .ReturnsAsync(relatedPerson);

        var result = await CreateSut().CreateAsync(
            "owner-1", 1, new CreatePersonRelationshipDto { RelatedPersonId = 2, RelationType = RelationType.Wife });

        result.Success.Should().BeTrue();
        _relationshipRepo.Verify(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Data.Entities.PersonRelationship>>()), Times.Never);
        _relationshipRepo.Verify(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Data.Entities.PersonRelationship>>()), Times.Never);
    }

    [Fact]
    public async Task Returns_conflict_when_new_parent_child_edge_would_close_a_cycle()
    {
        // Existing edge: person 1's father is person 2 (2 is parent of 1). Now person 2 tries to
        // claim person 1 as their father too — that would make 1 a parent of 2, closing a 2-node loop.
        var subject = MakePerson(2, "Ahmed", Gender.Male);
        var relatedPerson = MakePerson(1, "Youssef", Gender.Male);
        _personRepo.SetupSequence(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Person>>()))
            .ReturnsAsync(subject)
            .ReturnsAsync(relatedPerson);
        _relationshipRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Data.Entities.PersonRelationship>>())).ReturnsAsync(0);

        var existingEdge = new Data.Entities.PersonRelationship { Id = 1, PersonId = 1, RelatedPersonId = 2, RelationType = RelationType.Father };
        _relationshipRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Data.Entities.PersonRelationship>>()))
            .ReturnsAsync([existingEdge]);

        var result = await CreateSut().CreateAsync(
            "owner-1", 2, new CreatePersonRelationshipDto { RelatedPersonId = 1, RelationType = RelationType.Father });

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(409);
        result.ErrorCode.Should().Be("PersonRelationship.CircularChain");
        _relationshipRepo.Verify(r => r.AddAsync(It.IsAny<Data.Entities.PersonRelationship>()), Times.Never);
    }

    [Fact]
    public async Task Creates_relationship_and_its_auto_derived_inverse_cross_linked_by_id()
    {
        var subject = MakePerson(10, "Youssef", Gender.Male);
        var relatedPerson = MakePerson(20, "Ahmed", Gender.Male);
        _personRepo.SetupSequence(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Person>>()))
            .ReturnsAsync(subject)
            .ReturnsAsync(relatedPerson);
        _relationshipRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Data.Entities.PersonRelationship>>())).ReturnsAsync(0);
        _relationshipRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Data.Entities.PersonRelationship>>())).ReturnsAsync([]);

        var result = await CreateSut().CreateAsync(
            "owner-1", 10, new CreatePersonRelationshipDto { RelatedPersonId = 20, RelationType = RelationType.Father });

        result.Success.Should().BeTrue();
        result.StatusCode.Should().Be(201);
        result.Data!.PersonId.Should().Be(10);
        result.Data.RelatedPersonId.Should().Be(20);
        result.Data.RelatedPersonName.Should().Be("Ahmed");
        result.Data.RelationType.Should().Be(RelationType.Father);

        // Male subject's Father -> inverse Son, per RelationInverseResolver.
        _relationshipRepo.Verify(
            r => r.AddAsync(It.Is<Data.Entities.PersonRelationship>(pr => pr.PersonId == 10 && pr.RelatedPersonId == 20 && pr.RelationType == RelationType.Father)),
            Times.Once);
        _relationshipRepo.Verify(
            r => r.AddAsync(It.Is<Data.Entities.PersonRelationship>(pr => pr.PersonId == 20 && pr.RelatedPersonId == 10 && pr.RelationType == RelationType.Son)),
            Times.Once);
        _relationshipRepo.Verify(
            r => r.Update(It.Is<Data.Entities.PersonRelationship>(pr => pr.PersonId == 10 && pr.InverseRelationshipId == 101)),
            Times.Once);
        _relationshipRepo.Verify(
            r => r.Update(It.Is<Data.Entities.PersonRelationship>(pr => pr.PersonId == 20 && pr.InverseRelationshipId == 100)),
            Times.Once);
        _unitOfWork.Verify(u => u.CommitAsync(It.IsAny<IDbContextTransaction>()), Times.Once);
    }

    [Fact]
    public async Task Rolls_back_the_transaction_when_the_write_fails()
    {
        var subject = MakePerson(10, "Youssef", Gender.Male);
        var relatedPerson = MakePerson(20, "Ahmed", Gender.Male);
        _personRepo.SetupSequence(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Person>>()))
            .ReturnsAsync(subject)
            .ReturnsAsync(relatedPerson);
        _relationshipRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Data.Entities.PersonRelationship>>())).ReturnsAsync(0);
        _relationshipRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Data.Entities.PersonRelationship>>())).ReturnsAsync([]);
        _unitOfWork.Setup(u => u.SaveChangesAsync()).ThrowsAsync(new InvalidOperationException("db unavailable"));

        var act = () => CreateSut().CreateAsync(
            "owner-1", 10, new CreatePersonRelationshipDto { RelatedPersonId = 20, RelationType = RelationType.Father });

        await act.Should().ThrowAsync<InvalidOperationException>();
        _unitOfWork.Verify(u => u.RollbackAsync(It.IsAny<IDbContextTransaction>()), Times.Once);
        _unitOfWork.Verify(u => u.CommitAsync(It.IsAny<IDbContextTransaction>()), Times.Never);
    }
}
