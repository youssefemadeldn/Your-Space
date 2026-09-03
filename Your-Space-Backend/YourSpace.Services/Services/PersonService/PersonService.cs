using AutoMapper;
using Microsoft.Extensions.Localization;
using Microsoft.Extensions.Logging;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications.GroupSpecifications;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Repository.Specifications.PeopleSpecifications;
using YourSpace.Services.Helper;
using YourSpace.Services.Resources;
using YourSpace.Services.Services.PersonOccasionHistoryService.Dtos;
using YourSpace.Services.Services.PersonService.Dtos;

namespace YourSpace.Services.Services.PersonService;

public class PersonService(
    IUnitOfWork unitOfWork,
    IMapper mapper,
    IStringLocalizer<SharedResource> localizer,
    ILogger<PersonService> logger) : IPersonService
{
    private static class ErrorCodes
    {
        public const string NotFound = "Person.NotFound";
        public const string GroupNotFound = "Person.GroupNotFound";
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

        return ServiceResult<PersonDetailsDto>.Ok(dto);
    }

    public async Task<ServiceResult<PaginatedResultDto<PersonProfileDto>>> GetAllAsync(string ownerUserId, int? groupId, string? search, PaginationSpecification pagination)
    {
        logger.LogInformation("Fetching persons for user {UserId}", ownerUserId);

        var repo = unitOfWork.Repository<Person, int>();
        var totalItems = await repo.CountWithSpecAsync(new PersonWithSpecs(ownerUserId, groupId, search));
        var persons = await repo.ListAllWithSpecAsync(new PersonWithSpecs(ownerUserId, groupId, search, pagination));

        var reciprocityPersonIds = await GetReciprocityPersonIdsAsync(ownerUserId);

        var items = persons.Select(p =>
        {
            var dto = mapper.Map<PersonProfileDto>(p);
            dto.HasReciprocityHistory = reciprocityPersonIds.Contains(p.Id);
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

        var repo = unitOfWork.Repository<Person, int>();
        var person = new Person
        {
            OwnerUserId = ownerUserId,
            Name = dto.Name,
            PhoneNumber = dto.PhoneNumber,
            PhoneNumber2 = dto.PhoneNumber2,
            Gender = dto.Gender,
            GroupId = dto.GroupId,
            Notes = dto.Notes
        };

        await repo.AddAsync(person);
        await unitOfWork.SaveChangesAsync();

        person.Group = group;
        var result = mapper.Map<PersonDetailsDto>(person);
        result.OccasionHistory = [];
        result.HasReciprocityHistory = false;

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

    private async Task<HashSet<int>> GetReciprocityPersonIdsAsync(string ownerUserId)
    {
        var historyRepo = unitOfWork.Repository<PersonOccasionHistory, int>();
        var history = await historyRepo.ListAllWithSpecAsync(PersonOccasionHistoryWithSpecs.ReciprocityCandidates(ownerUserId));
        return history.Select(h => h.PersonId).ToHashSet();
    }
}
