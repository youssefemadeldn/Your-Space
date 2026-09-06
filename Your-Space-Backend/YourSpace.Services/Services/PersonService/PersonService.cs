using AutoMapper;
using Microsoft.Extensions.Localization;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications.GroupSpecifications;
using YourSpace.Repository.Specifications.LocationSpecifications;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Repository.Specifications.PeopleSpecifications;
using YourSpace.Services.Helper;
using YourSpace.Services.Resources;
using YourSpace.Services.Services.PersonOccasionHistoryService.Dtos;
using YourSpace.Services.Services.PersonRelationshipService.Dtos;
using YourSpace.Services.Services.PersonService.Dtos;
using YourSpace.Services.Services.StorageService;

namespace YourSpace.Services.Services.PersonService;

public class PersonService(
    IUnitOfWork unitOfWork,
    IMapper mapper,
    IR2StorageService r2StorageService,
    IOptions<R2Settings> r2Options,
    IStringLocalizer<SharedResource> localizer,
    ILogger<PersonService> logger) : IPersonService
{
    private static class ErrorCodes
    {
        public const string NotFound = "Person.NotFound";
        public const string GroupNotFound = "Person.GroupNotFound";
        public const string SubGroupInvalid = "Person.SubGroupId.Invalid";
        public const string GovernorateInvalid = "Person.GovernorateId.Invalid";
        public const string CityInvalid = "Person.CityId.Invalid";
        public const string NeighborhoodInvalid = "Person.NeighborhoodId.Invalid";
    }

    public async Task<ServiceResult<PersonDetailsDto>> GetDetailsAsync(string ownerUserId, int id)
    {
        var repo = unitOfWork.Repository<Person, int>();
        var person = await repo.GetByIdWithSpecAsync(new PersonWithSpecs(id, ownerUserId));

        if (person is null)
        {
            logger.LogWarning("Person {PersonId} not found for user {UserId}", id, ownerUserId);
            return ServiceResult<PersonDetailsDto>.NotFound(localizer["Person.NotFound"], ErrorCodes.NotFound);
        }

        var dto = mapper.Map<PersonDetailsDto>(person);
        var history = await GetHistoryAsync(person.Id, ownerUserId);
        dto.OccasionHistory = history;
        dto.HasReciprocityHistory = history.Any(h => h.InvitedMe);
        dto.Relationships = await GetRelationshipsAsync(person.Id, ownerUserId);
        dto.PrimaryPhotoUrl = await ResolvePrimaryPhotoUrlAsync(person.Id, ownerUserId);

        return ServiceResult<PersonDetailsDto>.Ok(dto);
    }

    public async Task<ServiceResult<PaginatedResultDto<PersonProfileDto>>> GetAllAsync(
        string ownerUserId, int? groupId, int? subGroupId, int? governorateId, int? cityId, int? neighborhoodId,
        string? search, PaginationSpecification pagination)
    {
        logger.LogInformation("Fetching persons for user {UserId}", ownerUserId);

        var filter = new PersonListFilter
        {
            GroupId = groupId,
            SubGroupId = subGroupId,
            GovernorateId = governorateId,
            CityId = cityId,
            NeighborhoodId = neighborhoodId,
            Search = search
        };

        var repo = unitOfWork.Repository<Person, int>();
        var totalItems = await repo.CountWithSpecAsync(new PersonWithSpecs(ownerUserId, filter));
        var persons = await repo.ListAllWithSpecAsync(new PersonWithSpecs(ownerUserId, filter, pagination));

        var reciprocityPersonIds = await GetReciprocityPersonIdsAsync(ownerUserId);
        var personIds = persons.Select(p => p.Id).ToList();
        var photoUrlByPersonId = await ResolvePrimaryPhotoUrlsAsync(personIds, ownerUserId);

        var items = persons.Select(p =>
        {
            var dto = mapper.Map<PersonProfileDto>(p);
            dto.HasReciprocityHistory = reciprocityPersonIds.Contains(p.Id);
            dto.PrimaryPhotoUrl = photoUrlByPersonId.GetValueOrDefault(p.Id);
            return dto;
        }).ToList();

        var totalPages = (int)Math.Ceiling(totalItems / (double)pagination.PageSize);

        return ServiceResult<PaginatedResultDto<PersonProfileDto>>.Ok(
            new PaginatedResultDto<PersonProfileDto>(items, pagination.PageIndex, pagination.PageSize, totalItems, totalPages));
    }

    public async Task<ServiceResult<PersonDetailsDto>> CreateAsync(string ownerUserId, CreatePersonDto dto)
    {
        logger.LogInformation("Creating person {PersonName} for user {UserId}", dto.Name, ownerUserId);

        var groupRepo = unitOfWork.Repository<Group, int>();
        var group = await groupRepo.GetByIdWithSpecAsync(new GroupWithSpecs(dto.GroupId, ownerUserId));
        if (group is null)
        {
            logger.LogWarning("Create person failed — group {GroupId} not found for user {UserId}", dto.GroupId, ownerUserId);
            return ServiceResult<PersonDetailsDto>.NotFound(localizer["Person.GroupNotFound"], ErrorCodes.GroupNotFound);
        }

        SubGroup? subGroup = null;
        if (dto.SubGroupId is int subGroupId)
        {
            var subGroupRepo = unitOfWork.Repository<SubGroup, int>();
            subGroup = await subGroupRepo.GetByIdWithSpecAsync(new SubGroupWithSpecs(subGroupId, dto.GroupId, ownerUserId));
            if (subGroup is null)
            {
                logger.LogWarning("Create person failed — subgroup {SubGroupId} invalid for group {GroupId}, user {UserId}", subGroupId, dto.GroupId, ownerUserId);
                return ServiceResult<PersonDetailsDto>.NotFound(localizer["Person.SubGroupId.Invalid"], ErrorCodes.SubGroupInvalid);
            }
        }

        var governorateRepo = unitOfWork.Repository<Governorate, int>();
        var governorate = await governorateRepo.GetByIdWithSpecAsync(new GovernorateWithSpecs(dto.GovernorateId, ownerUserId));
        if (governorate is null)
        {
            logger.LogWarning("Create person failed — governorate {GovernorateId} not visible to user {UserId}", dto.GovernorateId, ownerUserId);
            return ServiceResult<PersonDetailsDto>.NotFound(localizer["Person.GovernorateId.Invalid"], ErrorCodes.GovernorateInvalid);
        }

        City? city = null;
        if (dto.CityId is int cityId)
        {
            var cityRepo = unitOfWork.Repository<City, int>();
            city = await cityRepo.GetByIdWithSpecAsync(new CityWithSpecs(cityId, dto.GovernorateId, ownerUserId));
            if (city is null)
            {
                logger.LogWarning("Create person failed — city {CityId} invalid for governorate {GovernorateId}, user {UserId}", cityId, dto.GovernorateId, ownerUserId);
                return ServiceResult<PersonDetailsDto>.NotFound(localizer["Person.CityId.Invalid"], ErrorCodes.CityInvalid);
            }
        }

        Neighborhood? neighborhood = null;
        if (dto.NeighborhoodId is int neighborhoodId)
        {
            if (dto.CityId is null)
            {
                logger.LogWarning("Create person failed — neighborhood {NeighborhoodId} provided without a city, user {UserId}", neighborhoodId, ownerUserId);
                return ServiceResult<PersonDetailsDto>.NotFound(localizer["Person.NeighborhoodId.Invalid"], ErrorCodes.NeighborhoodInvalid);
            }

            var neighborhoodRepo = unitOfWork.Repository<Neighborhood, int>();
            neighborhood = await neighborhoodRepo.GetByIdWithSpecAsync(new NeighborhoodWithSpecs(neighborhoodId, dto.CityId.Value, ownerUserId));
            if (neighborhood is null)
            {
                logger.LogWarning("Create person failed — neighborhood {NeighborhoodId} invalid for city {CityId}, user {UserId}", neighborhoodId, dto.CityId, ownerUserId);
                return ServiceResult<PersonDetailsDto>.NotFound(localizer["Person.NeighborhoodId.Invalid"], ErrorCodes.NeighborhoodInvalid);
            }
        }

        var repo = unitOfWork.Repository<Person, int>();
        var person = new Person
        {
            OwnerUserId = ownerUserId,
            Name = dto.Name,
            PhoneNumber = dto.PhoneNumber,
            PhoneNumber2 = dto.PhoneNumber2,
            Gender = dto.Gender,
            GroupId = dto.GroupId,
            SubGroupId = dto.SubGroupId,
            GovernorateId = dto.GovernorateId,
            CityId = dto.CityId,
            NeighborhoodId = dto.NeighborhoodId,
            Notes = dto.Notes
        };

        await repo.AddAsync(person);
        await unitOfWork.SaveChangesAsync();

        person.Group = group;
        person.SubGroup = subGroup;
        person.Governorate = governorate;
        person.City = city;
        person.Neighborhood = neighborhood;

        var result = mapper.Map<PersonDetailsDto>(person);
        result.OccasionHistory = [];
        result.Relationships = [];
        result.HasReciprocityHistory = false;
        // Brand new person — PersonImage rows require an existing PersonId, so there's never a
        // photo to resolve on the create response.
        result.PrimaryPhotoUrl = null;

        return ServiceResult<PersonDetailsDto>.Created(result);
    }

    public async Task<ServiceResult<PersonDetailsDto>> UpdateAsync(string ownerUserId, UpdatePersonDto dto)
    {
        var repo = unitOfWork.Repository<Person, int>();
        var person = await repo.GetByIdWithSpecAsync(new PersonWithSpecs(dto.Id, ownerUserId));

        if (person is null)
        {
            logger.LogWarning("Person {PersonId} not found for user {UserId}", dto.Id, ownerUserId);
            return ServiceResult<PersonDetailsDto>.NotFound(localizer["Person.NotFound"], ErrorCodes.NotFound);
        }

        var groupChanged = false;
        if (dto.GroupId is not null && dto.GroupId != person.GroupId)
        {
            var groupRepo = unitOfWork.Repository<Group, int>();
            var group = await groupRepo.GetByIdWithSpecAsync(new GroupWithSpecs(dto.GroupId.Value, ownerUserId));
            if (group is null)
            {
                logger.LogWarning("Update person failed — group {GroupId} not found for user {UserId}", dto.GroupId, ownerUserId);
                return ServiceResult<PersonDetailsDto>.NotFound(localizer["Person.GroupNotFound"], ErrorCodes.GroupNotFound);
            }

            person.GroupId = dto.GroupId.Value;
            person.Group = group;
            groupChanged = true;
        }

        var subGroupRepo = unitOfWork.Repository<SubGroup, int>();
        if (dto.SubGroupId is int newSubGroupId)
        {
            var subGroup = await subGroupRepo.GetByIdWithSpecAsync(new SubGroupWithSpecs(newSubGroupId, person.GroupId, ownerUserId));
            if (subGroup is null)
            {
                logger.LogWarning("Update person failed — subgroup {SubGroupId} invalid for group {GroupId}, user {UserId}", newSubGroupId, person.GroupId, ownerUserId);
                return ServiceResult<PersonDetailsDto>.NotFound(localizer["Person.SubGroupId.Invalid"], ErrorCodes.SubGroupInvalid);
            }

            person.SubGroupId = newSubGroupId;
            person.SubGroup = subGroup;
        }
        else if (groupChanged)
        {
            // A new SubGroupId wasn't resubmitted in the same call, but the group changed under
            // it — the old subgroup no longer applies under the new group, so clear it rather
            // than silently leave a stale cross-group reference (the DTO's usual "null means
            // unchanged" convention would otherwise do the wrong thing here).
            person.SubGroupId = null;
            person.SubGroup = null;
        }

        var governorateChanged = false;
        if (dto.GovernorateId is not null && dto.GovernorateId != person.GovernorateId)
        {
            var governorateRepo = unitOfWork.Repository<Governorate, int>();
            var governorate = await governorateRepo.GetByIdWithSpecAsync(new GovernorateWithSpecs(dto.GovernorateId.Value, ownerUserId));
            if (governorate is null)
            {
                logger.LogWarning("Update person failed — governorate {GovernorateId} not visible to user {UserId}", dto.GovernorateId, ownerUserId);
                return ServiceResult<PersonDetailsDto>.NotFound(localizer["Person.GovernorateId.Invalid"], ErrorCodes.GovernorateInvalid);
            }

            person.GovernorateId = dto.GovernorateId.Value;
            person.Governorate = governorate;
            governorateChanged = true;
        }

        // Location fields are validate-and-reject, not auto-cleared (asymmetric vs. SubGroup by
        // design — see PersonService's class-level notes / the plan doc). The mobile cascading
        // picker never lets this scenario reach the API in normal use; this is a defense-in-depth
        // path for a direct/out-of-band API call.
        var cityRepo = unitOfWork.Repository<City, int>();
        var cityChanged = false;
        if (dto.CityId is int newCityId)
        {
            var city = await cityRepo.GetByIdWithSpecAsync(new CityWithSpecs(newCityId, person.GovernorateId, ownerUserId));
            if (city is null)
            {
                logger.LogWarning("Update person failed — city {CityId} invalid for governorate {GovernorateId}, user {UserId}", newCityId, person.GovernorateId, ownerUserId);
                return ServiceResult<PersonDetailsDto>.NotFound(localizer["Person.CityId.Invalid"], ErrorCodes.CityInvalid);
            }

            cityChanged = newCityId != person.CityId;
            person.CityId = newCityId;
            person.City = city;
        }
        else if (governorateChanged && person.CityId is not null)
        {
            var stillValidCity = await cityRepo.GetByIdWithSpecAsync(new CityWithSpecs(person.CityId.Value, person.GovernorateId, ownerUserId));
            if (stillValidCity is null)
            {
                logger.LogWarning(
                    "Update person rejected — existing city {CityId} no longer valid under new governorate {GovernorateId}, user {UserId}",
                    person.CityId, person.GovernorateId, ownerUserId);
                return ServiceResult<PersonDetailsDto>.Conflict(localizer["Person.CityId.Invalid"], ErrorCodes.CityInvalid);
            }
        }

        if (dto.NeighborhoodId is int newNeighborhoodId)
        {
            if (person.CityId is null)
            {
                logger.LogWarning("Update person failed — neighborhood {NeighborhoodId} provided without a city, user {UserId}", newNeighborhoodId, ownerUserId);
                return ServiceResult<PersonDetailsDto>.NotFound(localizer["Person.NeighborhoodId.Invalid"], ErrorCodes.NeighborhoodInvalid);
            }

            var neighborhoodRepo = unitOfWork.Repository<Neighborhood, int>();
            var neighborhood = await neighborhoodRepo.GetByIdWithSpecAsync(new NeighborhoodWithSpecs(newNeighborhoodId, person.CityId.Value, ownerUserId));
            if (neighborhood is null)
            {
                logger.LogWarning("Update person failed — neighborhood {NeighborhoodId} invalid for city {CityId}, user {UserId}", newNeighborhoodId, person.CityId, ownerUserId);
                return ServiceResult<PersonDetailsDto>.NotFound(localizer["Person.NeighborhoodId.Invalid"], ErrorCodes.NeighborhoodInvalid);
            }

            person.NeighborhoodId = newNeighborhoodId;
            person.Neighborhood = neighborhood;
        }
        else if (cityChanged && person.NeighborhoodId is not null)
        {
            var neighborhoodRepo = unitOfWork.Repository<Neighborhood, int>();
            var stillValidNeighborhood = await neighborhoodRepo.GetByIdWithSpecAsync(new NeighborhoodWithSpecs(person.NeighborhoodId.Value, person.CityId!.Value, ownerUserId));
            if (stillValidNeighborhood is null)
            {
                logger.LogWarning(
                    "Update person rejected — existing neighborhood {NeighborhoodId} no longer valid under new city {CityId}, user {UserId}",
                    person.NeighborhoodId, person.CityId, ownerUserId);
                return ServiceResult<PersonDetailsDto>.Conflict(localizer["Person.NeighborhoodId.Invalid"], ErrorCodes.NeighborhoodInvalid);
            }
        }

        if (dto.Name is not null)
        {
            person.Name = dto.Name;
        }

        if (dto.PhoneNumber is not null)
        {
            person.PhoneNumber = dto.PhoneNumber;
        }

        if (dto.PhoneNumber2 is not null)
        {
            person.PhoneNumber2 = dto.PhoneNumber2;
        }

        if (dto.Gender is not null)
        {
            person.Gender = dto.Gender.Value;
        }

        if (dto.Notes is not null)
        {
            person.Notes = dto.Notes;
        }

        person.UpdatedAt = DateTime.UtcNow;
        repo.Update(person);
        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("Person {PersonId} updated for user {UserId}", person.Id, ownerUserId);

        var result = mapper.Map<PersonDetailsDto>(person);
        var history = await GetHistoryAsync(person.Id, ownerUserId);
        result.OccasionHistory = history;
        result.HasReciprocityHistory = history.Any(h => h.InvitedMe);
        result.Relationships = await GetRelationshipsAsync(person.Id, ownerUserId);
        result.PrimaryPhotoUrl = await ResolvePrimaryPhotoUrlAsync(person.Id, ownerUserId);

        return ServiceResult<PersonDetailsDto>.Ok(result);
    }

    public async Task<ServiceResult> DeleteAsync(string ownerUserId, int id)
    {
        var repo = unitOfWork.Repository<Person, int>();
        var person = await repo.GetByIdWithSpecAsync(new PersonWithSpecs(id, ownerUserId));

        if (person is null)
        {
            logger.LogWarning("Person {PersonId} not found for user {UserId}", id, ownerUserId);
            return ServiceResult.NotFound(localizer["Person.NotFound"], ErrorCodes.NotFound);
        }

        person.DeletedAt = DateTime.UtcNow;
        person.UpdatedAt = DateTime.UtcNow;
        repo.Update(person);
        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("Person {PersonId} soft-deleted for user {UserId}", id, ownerUserId);
        return ServiceResult.Ok("Person deleted successfully.");
    }

    private async Task<List<PersonOccasionHistoryProfileDto>> GetHistoryAsync(int personId, string ownerUserId)
    {
        var historyRepo = unitOfWork.Repository<PersonOccasionHistory, int>();
        var history = await historyRepo.ListAllWithSpecAsync(PersonOccasionHistoryWithSpecs.ForPerson(personId, ownerUserId));
        return history.Select(mapper.Map<PersonOccasionHistoryProfileDto>).ToList();
    }

    private async Task<List<PersonRelationshipProfileDto>> GetRelationshipsAsync(int personId, string ownerUserId)
    {
        var relationshipRepo = unitOfWork.Repository<PersonRelationship, int>();
        var relationships = await relationshipRepo.ListAllWithSpecAsync(PersonRelationshipWithSpecs.ForPerson(personId, ownerUserId));
        return relationships.Select(r => new PersonRelationshipProfileDto
        {
            Id = r.Id,
            RelatedPersonId = r.RelatedPersonId,
            RelatedPersonName = r.RelatedPerson.Name,
            RelationType = r.RelationType
        }).ToList();
    }

    private async Task<HashSet<int>> GetReciprocityPersonIdsAsync(string ownerUserId)
    {
        var historyRepo = unitOfWork.Repository<PersonOccasionHistory, int>();
        var history = await historyRepo.ListAllWithSpecAsync(PersonOccasionHistoryWithSpecs.ReciprocityCandidates(ownerUserId));
        return history.Select(h => h.PersonId).ToHashSet();
    }

    private async Task<string?> ResolvePrimaryPhotoUrlAsync(int personId, string ownerUserId)
    {
        var urls = await ResolvePrimaryPhotoUrlsAsync([personId], ownerUserId);
        return urls.GetValueOrDefault(personId);
    }

    // Batch-resolves primary-photo presigned URLs for a whole page of persons in one query, then
    // one (cheap, local — see IR2StorageService's own doc comment) presign call per person that
    // actually has a primary photo — not an extra DB query per person.
    private async Task<Dictionary<int, string>> ResolvePrimaryPhotoUrlsAsync(List<int> personIds, string ownerUserId)
    {
        if (personIds.Count == 0)
        {
            return [];
        }

        var imageRepo = unitOfWork.Repository<PersonImage, int>();
        var primaryImages = await imageRepo.ListAllWithSpecAsync(PersonImageWithSpecs.PrimaryForPersons(personIds, ownerUserId));

        var result = new Dictionary<int, string>();
        foreach (var image in primaryImages)
        {
            result[image.PersonId] = await r2StorageService.GetPresignedUrlAsync(r2Options.Value.PeoplePhotosBucketName, image.ObjectKey);
        }

        return result;
    }
}
