using Microsoft.Extensions.Localization;
using Microsoft.Extensions.Logging;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications.PeopleSpecifications;
using YourSpace.Services.Helper;
using YourSpace.Services.Resources;
using YourSpace.Services.Services.PersonRelationshipService.Dtos;

namespace YourSpace.Services.Services.PersonRelationshipService;

public class PersonRelationshipService(
    IUnitOfWork unitOfWork,
    IStringLocalizer<SharedResource> localizer,
    ILogger<PersonRelationshipService> logger) : IPersonRelationshipService
{
    private static class ErrorCodes
    {
        public const string NotFound = "PersonRelationship.NotFound";
        public const string PersonNotFound = "Person.NotFound";
        public const string RelatedPersonNotFound = "PersonRelationship.RelatedPersonNotFound";
        public const string SelfLink = "PersonRelationship.SelfLink";
        public const string DuplicateParent = "PersonRelationship.DuplicateParent";
        public const string CircularChain = "PersonRelationship.CircularChain";
    }

    private static readonly HashSet<RelationType> ParentTypes = [RelationType.Father, RelationType.Mother];
    private static readonly HashSet<RelationType> ChildTypes = [RelationType.Son, RelationType.Daughter];

    public async Task<ServiceResult<IReadOnlyList<PersonRelationshipProfileDto>>> GetAllAsync(string ownerUserId, int personId)
    {
        if (!await PersonExistsAsync(personId, ownerUserId))
        {
            logger.LogWarning("Person {PersonId} not found for user {UserId}", personId, ownerUserId);
            return ServiceResult<IReadOnlyList<PersonRelationshipProfileDto>>.NotFound(localizer["Person.NotFound"], ErrorCodes.PersonNotFound);
        }

        var repo = unitOfWork.Repository<PersonRelationship, int>();
        var relationships = await repo.ListAllWithSpecAsync(PersonRelationshipWithSpecs.ForPerson(personId, ownerUserId));

        var items = relationships.Select(BuildProfileDto).ToList();
        return ServiceResult<IReadOnlyList<PersonRelationshipProfileDto>>.Ok(items);
    }

    public async Task<ServiceResult<PersonRelationshipDetailsDto>> CreateAsync(string ownerUserId, int personId, CreatePersonRelationshipDto dto)
    {
        if (personId == dto.RelatedPersonId)
        {
            logger.LogWarning("Self-link rejected for person {PersonId}, user {UserId}", personId, ownerUserId);
            return ServiceResult<PersonRelationshipDetailsDto>.Conflict(localizer["PersonRelationship.SelfLink"], ErrorCodes.SelfLink);
        }

        var personRepo = unitOfWork.Repository<Person, int>();
        var person = await personRepo.GetByIdWithSpecAsync(new PersonWithSpecs(personId, ownerUserId));
        if (person is null)
        {
            logger.LogWarning("Person {PersonId} not found for user {UserId}", personId, ownerUserId);
            return ServiceResult<PersonRelationshipDetailsDto>.NotFound(localizer["Person.NotFound"], ErrorCodes.PersonNotFound);
        }

        var relatedPerson = await personRepo.GetByIdWithSpecAsync(new PersonWithSpecs(dto.RelatedPersonId, ownerUserId));
        if (relatedPerson is null)
        {
            logger.LogWarning("Related person {RelatedPersonId} not found for user {UserId}", dto.RelatedPersonId, ownerUserId);
            return ServiceResult<PersonRelationshipDetailsDto>.NotFound(localizer["PersonRelationship.RelatedPersonNotFound"], ErrorCodes.RelatedPersonNotFound);
        }

        var relationshipRepo = unitOfWork.Repository<PersonRelationship, int>();

        if (ParentTypes.Contains(dto.RelationType))
        {
            var existingParentCount = await relationshipRepo.CountWithSpecAsync(
                PersonRelationshipWithSpecs.ByPersonAndType(personId, ownerUserId, dto.RelationType));
            if (existingParentCount > 0)
            {
                logger.LogWarning("Duplicate {RelationType} rejected for person {PersonId}, user {UserId}", dto.RelationType, personId, ownerUserId);
                return ServiceResult<PersonRelationshipDetailsDto>.Conflict(localizer["PersonRelationship.DuplicateParent"], ErrorCodes.DuplicateParent);
            }
        }

        if (ParentTypes.Contains(dto.RelationType) || ChildTypes.Contains(dto.RelationType))
        {
            var (parentId, childId) = NormalizeParentChild(personId, dto.RelatedPersonId, dto.RelationType);
            if (await WouldCreateCycleAsync(ownerUserId, parentId, childId))
            {
                logger.LogWarning(
                    "Circular chain rejected linking parent {ParentId} to child {ChildId} for user {UserId}", parentId, childId, ownerUserId);
                return ServiceResult<PersonRelationshipDetailsDto>.Conflict(localizer["PersonRelationship.CircularChain"], ErrorCodes.CircularChain);
            }
        }

        var inverseType = RelationInverseResolver.Resolve(dto.RelationType, person.Gender);

        var original = new PersonRelationship
        {
            PersonId = personId,
            RelatedPersonId = dto.RelatedPersonId,
            RelationType = dto.RelationType
        };
        var inverse = new PersonRelationship
        {
            PersonId = dto.RelatedPersonId,
            RelatedPersonId = personId,
            RelationType = inverseType
        };

        var transaction = await unitOfWork.BeginTransactionAsync();
        try
        {
            // Two SaveChangesAsync calls inside one transaction — the rows need real Ids from the
            // first save before they can be cross-linked to each other in the second.
            await relationshipRepo.AddAsync(original);
            await relationshipRepo.AddAsync(inverse);
            await unitOfWork.SaveChangesAsync();

            original.InverseRelationshipId = inverse.Id;
            inverse.InverseRelationshipId = original.Id;
            relationshipRepo.Update(original);
            relationshipRepo.Update(inverse);
            await unitOfWork.SaveChangesAsync();

            await unitOfWork.CommitAsync(transaction);
        }
        catch
        {
            await unitOfWork.RollbackAsync(transaction);
            throw;
        }

        logger.LogInformation(
            "Relationship {RelationType} created from person {PersonId} to {RelatedPersonId}, inverse {InverseType} auto-derived, user {UserId}",
            dto.RelationType, personId, dto.RelatedPersonId, inverseType, ownerUserId);

        return ServiceResult<PersonRelationshipDetailsDto>.Created(new PersonRelationshipDetailsDto
        {
            Id = original.Id,
            PersonId = personId,
            RelatedPersonId = relatedPerson.Id,
            RelatedPersonName = relatedPerson.Name,
            RelationType = original.RelationType,
            CreatedAt = original.CreatedAt
        });
    }

    public async Task<ServiceResult> DeleteAsync(string ownerUserId, int personId, int relationshipId)
    {
        var repo = unitOfWork.Repository<PersonRelationship, int>();
        var relationship = await repo.GetByIdWithSpecAsync(PersonRelationshipWithSpecs.ById(relationshipId, personId, ownerUserId));

        if (relationship is null)
        {
            logger.LogWarning("Relationship {RelationshipId} not found for person {PersonId}, user {UserId}", relationshipId, personId, ownerUserId);
            return ServiceResult.NotFound(localizer["PersonRelationship.NotFound"], ErrorCodes.NotFound);
        }

        var transaction = await unitOfWork.BeginTransactionAsync();
        try
        {
            // Cascade-delete the auto-derived inverse row explicitly, via the stored link — not by
            // re-matching (PersonId, RelatedPersonId) reversed, since two rows can legitimately
            // share that pair with different RelationTypes.
            if (relationship.InverseRelationshipId is int inverseId)
            {
                var inverse = await repo.GetByIdAsync(inverseId);
                if (inverse is not null)
                {
                    repo.Delete(inverse);
                }
            }

            repo.Delete(relationship);
            await unitOfWork.SaveChangesAsync();
            await unitOfWork.CommitAsync(transaction);
        }
        catch
        {
            await unitOfWork.RollbackAsync(transaction);
            throw;
        }

        logger.LogInformation("Relationship {RelationshipId} (and its inverse) deleted for person {PersonId}, user {UserId}", relationshipId, personId, ownerUserId);
        return ServiceResult.Ok("Relationship deleted successfully.");
    }

    private async Task<bool> PersonExistsAsync(int personId, string ownerUserId)
    {
        var personRepo = unitOfWork.Repository<Person, int>();
        return await personRepo.GetByIdWithSpecAsync(new PersonWithSpecs(personId, ownerUserId)) is not null;
    }

    // A row (PersonId=Y, RelatedPersonId=X, RelationType=Father) reads "Y's father is X" — X is the
    // parent, Y is the child. A row (PersonId=Y, RelatedPersonId=X, RelationType=Son) reads "Y's son
    // is X" — Y is the parent, X is the child.
    private static (int ParentId, int ChildId) NormalizeParentChild(int personId, int relatedPersonId, RelationType type)
        => ParentTypes.Contains(type) ? (relatedPersonId, personId) : (personId, relatedPersonId);

    // In-memory graph walk, bounded by one user's People count (cheap at this app's scale). Adding
    // a new parentId -> childId edge would close a cycle if childId can already reach parentId by
    // walking existing parent -> child edges (i.e. childId is already an ancestor of parentId).
    private async Task<bool> WouldCreateCycleAsync(string ownerUserId, int parentId, int childId)
    {
        var repo = unitOfWork.Repository<PersonRelationship, int>();
        var edges = await repo.ListAllWithSpecAsync(PersonRelationshipWithSpecs.ParentChildEdgesForOwner(ownerUserId));

        var adjacency = new Dictionary<int, List<int>>();
        foreach (var edge in edges)
        {
            var (edgeParentId, edgeChildId) = NormalizeParentChild(edge.PersonId, edge.RelatedPersonId, edge.RelationType);
            if (!adjacency.TryGetValue(edgeParentId, out var children))
            {
                children = [];
                adjacency[edgeParentId] = children;
            }
            children.Add(edgeChildId);
        }

        var visited = new HashSet<int> { childId };
        var queue = new Queue<int>();
        queue.Enqueue(childId);

        while (queue.Count > 0)
        {
            var current = queue.Dequeue();
            if (current == parentId)
            {
                return true;
            }

            if (!adjacency.TryGetValue(current, out var children))
            {
                continue;
            }

            foreach (var next in children)
            {
                if (visited.Add(next))
                {
                    queue.Enqueue(next);
                }
            }
        }

        return false;
    }

    private static PersonRelationshipProfileDto BuildProfileDto(PersonRelationship relationship) => new()
    {
        Id = relationship.Id,
        RelatedPersonId = relationship.RelatedPersonId,
        RelatedPersonName = relationship.RelatedPerson.Name,
        RelationType = relationship.RelationType
    };
}
