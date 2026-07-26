using AutoMapper;
using Microsoft.Extensions.Localization;
using Microsoft.Extensions.Logging;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Repository.Specifications.PeopleSpecifications;
using YourSpace.Services.Helper;
using YourSpace.Services.Resources;
using YourSpace.Services.Services.PersonOccasionHistoryService.Dtos;

namespace YourSpace.Services.Services.PersonOccasionHistoryService;

public class PersonOccasionHistoryService(
    IUnitOfWork unitOfWork,
    IMapper mapper,
    IStringLocalizer<SharedResource> localizer,
    ILogger<PersonOccasionHistoryService> logger) : IPersonOccasionHistoryService
{
    private static class ErrorCodes
    {
        public const string NotFound = "PersonOccasionHistory.NotFound";
        public const string PersonNotFound = "Person.NotFound";
    }

    public async Task<ServiceResult<PersonOccasionHistoryDetailsDto>> GetDetailsAsync(string ownerUserId, int personId, int id)
    {
        var repo = unitOfWork.Repository<PersonOccasionHistory, int>();
        var entry = await repo.GetByIdWithSpecAsync(PersonOccasionHistoryWithSpecs.ById(id, personId, ownerUserId));

        if (entry is null)
        {
            logger.LogWarning("Occasion history {HistoryId} not found for person {PersonId}, user {UserId}", id, personId, ownerUserId);
            return ServiceResult<PersonOccasionHistoryDetailsDto>.NotFound(localizer["PersonOccasionHistory.NotFound"], ErrorCodes.NotFound);
        }

        return ServiceResult<PersonOccasionHistoryDetailsDto>.Ok(mapper.Map<PersonOccasionHistoryDetailsDto>(entry));
    }

    public async Task<ServiceResult<PaginatedResultDto<PersonOccasionHistoryProfileDto>>> GetAllAsync(string ownerUserId, int personId, PaginationSpecification pagination)
    {
        if (!await PersonExistsAsync(personId, ownerUserId))
        {
            logger.LogWarning("Person {PersonId} not found for user {UserId}", personId, ownerUserId);
            return ServiceResult<PaginatedResultDto<PersonOccasionHistoryProfileDto>>.NotFound(localizer["Person.NotFound"], ErrorCodes.PersonNotFound);
        }

        var repo = unitOfWork.Repository<PersonOccasionHistory, int>();
        var totalItems = await repo.CountWithSpecAsync(PersonOccasionHistoryWithSpecs.ForPerson(personId, ownerUserId));
        var entries = await repo.ListAllWithSpecAsync(new PersonOccasionHistoryWithSpecs(personId, ownerUserId, pagination));

        var items = entries.Select(mapper.Map<PersonOccasionHistoryProfileDto>).ToList();
        var totalPages = (int)Math.Ceiling(totalItems / (double)pagination.PageSize);

        return ServiceResult<PaginatedResultDto<PersonOccasionHistoryProfileDto>>.Ok(
            new PaginatedResultDto<PersonOccasionHistoryProfileDto>(items, pagination.PageIndex, pagination.PageSize, totalItems, totalPages));
    }

    public async Task<ServiceResult<PersonOccasionHistoryDetailsDto>> CreateAsync(string ownerUserId, int personId, CreatePersonOccasionHistoryDto dto)
    {
        if (!await PersonExistsAsync(personId, ownerUserId))
        {
            logger.LogWarning("Create occasion history failed — person {PersonId} not found for user {UserId}", personId, ownerUserId);
            return ServiceResult<PersonOccasionHistoryDetailsDto>.NotFound(localizer["Person.NotFound"], ErrorCodes.PersonNotFound);
        }

        logger.LogInformation("Adding occasion history for person {PersonId}, user {UserId}", personId, ownerUserId);

        var repo = unitOfWork.Repository<PersonOccasionHistory, int>();
        var entry = new PersonOccasionHistory
        {
            PersonId = personId,
            InvitedMe = dto.InvitedMe,
            // Enforced server-side too (not just by the validator) — an occasion the person didn't
            // invite the user to can never carry an invite method.
            InviteMethod = dto.InvitedMe ? dto.InviteMethod : null,
            OccasionName = dto.OccasionName,
            OccasionDate = dto.OccasionDate,
            Notes = dto.Notes
        };

        await repo.AddAsync(entry);
        await unitOfWork.SaveChangesAsync();

        return ServiceResult<PersonOccasionHistoryDetailsDto>.Created(mapper.Map<PersonOccasionHistoryDetailsDto>(entry));
    }

    public async Task<ServiceResult<PersonOccasionHistoryDetailsDto>> UpdateAsync(string ownerUserId, int personId, UpdatePersonOccasionHistoryDto dto)
    {
        var repo = unitOfWork.Repository<PersonOccasionHistory, int>();
        var entry = await repo.GetByIdWithSpecAsync(PersonOccasionHistoryWithSpecs.ById(dto.Id, personId, ownerUserId));

        if (entry is null)
        {
            logger.LogWarning("Occasion history {HistoryId} not found for person {PersonId}, user {UserId}", dto.Id, personId, ownerUserId);
            return ServiceResult<PersonOccasionHistoryDetailsDto>.NotFound(localizer["PersonOccasionHistory.NotFound"], ErrorCodes.NotFound);
        }

        // Resolved against the *merged* state, not just this request's fields — a validator can't
        // see what InvitedMe already is on the existing row when the caller only updates other fields.
        var resolvedInvitedMe = dto.InvitedMe ?? entry.InvitedMe;
        entry.InvitedMe = resolvedInvitedMe;
        entry.InviteMethod = resolvedInvitedMe ? (dto.InviteMethod ?? entry.InviteMethod) : null;

        if (dto.OccasionName is not null)
        {
            entry.OccasionName = dto.OccasionName;
        }

        if (dto.OccasionDate is not null)
        {
            entry.OccasionDate = dto.OccasionDate;
        }

        if (dto.Notes is not null)
        {
            entry.Notes = dto.Notes;
        }

        entry.UpdatedAt = DateTime.UtcNow;
        repo.Update(entry);
        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("Occasion history {HistoryId} updated for person {PersonId}, user {UserId}", entry.Id, personId, ownerUserId);
        return ServiceResult<PersonOccasionHistoryDetailsDto>.Ok(mapper.Map<PersonOccasionHistoryDetailsDto>(entry));
    }

    public async Task<ServiceResult> DeleteAsync(string ownerUserId, int personId, int id)
    {
        var repo = unitOfWork.Repository<PersonOccasionHistory, int>();
        var entry = await repo.GetByIdWithSpecAsync(PersonOccasionHistoryWithSpecs.ById(id, personId, ownerUserId));

        if (entry is null)
        {
            logger.LogWarning("Occasion history {HistoryId} not found for person {PersonId}, user {UserId}", id, personId, ownerUserId);
            return ServiceResult.NotFound(localizer["PersonOccasionHistory.NotFound"], ErrorCodes.NotFound);
        }

        repo.Delete(entry);
        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("Occasion history {HistoryId} deleted for person {PersonId}, user {UserId}", id, personId, ownerUserId);
        return ServiceResult.Ok("Occasion history entry deleted successfully.");
    }

    private async Task<bool> PersonExistsAsync(int personId, string ownerUserId)
    {
        var personRepo = unitOfWork.Repository<Person, int>();
        return await personRepo.GetByIdWithSpecAsync(new PersonWithSpecs(personId, ownerUserId)) is not null;
    }
}
