using AutoMapper;
using Microsoft.Extensions.Localization;
using Microsoft.Extensions.Logging;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications.LocationSpecifications;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Repository.Specifications.PeopleSpecifications;
using YourSpace.Services.Helper;
using YourSpace.Services.Resources;
using YourSpace.Services.Services.GovernorateService.Dtos;

namespace YourSpace.Services.Services.GovernorateService;

public class GovernorateService(
    IUnitOfWork unitOfWork,
    IMapper mapper,
    IStringLocalizer<SharedResource> localizer,
    ILogger<GovernorateService> logger) : IGovernorateService
{
    private static class ErrorCodes
    {
        public const string NotFound = "Governorate.NotFound";
        public const string Locked = "Governorate.Locked";
        public const string NotOwned = "Governorate.NotOwned";
        public const string HasActiveCities = "Governorate.HasActiveCities";
        public const string HasActivePersons = "Governorate.HasActivePersons";
    }

    public async Task<ServiceResult<GovernorateDetailsDto>> GetDetailsAsync(string ownerUserId, int id)
    {
        var repo = unitOfWork.Repository<Governorate, int>();
        var governorate = await repo.GetByIdWithSpecAsync(new GovernorateWithSpecs(id, ownerUserId));

        if (governorate is null)
        {
            logger.LogWarning("Governorate {GovernorateId} not visible to user {UserId}", id, ownerUserId);
            return ServiceResult<GovernorateDetailsDto>.NotFound(localizer["Governorate.NotFound"], ErrorCodes.NotFound);
        }

        return ServiceResult<GovernorateDetailsDto>.Ok(mapper.Map<GovernorateDetailsDto>(governorate));
    }

    public async Task<ServiceResult<PaginatedResultDto<GovernorateProfileDto>>> GetAllAsync(
        string ownerUserId, string? search, PaginationSpecification pagination)
    {
        logger.LogInformation("Fetching governorates for user {UserId}", ownerUserId);

        var repo = unitOfWork.Repository<Governorate, int>();
        var totalItems = await repo.CountWithSpecAsync(new GovernorateWithSpecs(ownerUserId, search));
        var governorates = await repo.ListAllWithSpecAsync(new GovernorateWithSpecs(ownerUserId, search, pagination));

        var personRepo = unitOfWork.Repository<Person, int>();
        var allPersons = await personRepo.ListAllWithSpecAsync(new PersonWithSpecs(ownerUserId, (int?)null, (string?)null));
        var countByGovernorate = allPersons.GroupBy(p => p.GovernorateId).ToDictionary(g => g.Key, g => g.Count());

        var items = governorates.Select(g =>
        {
            var dto = mapper.Map<GovernorateProfileDto>(g);
            dto.PersonCount = countByGovernorate.GetValueOrDefault(g.Id, 0);
            return dto;
        }).ToList();

        var totalPages = (int)Math.Ceiling(totalItems / (double)pagination.PageSize);
        return ServiceResult<PaginatedResultDto<GovernorateProfileDto>>.Ok(
            new PaginatedResultDto<GovernorateProfileDto>(items, pagination.PageIndex, pagination.PageSize, totalItems, totalPages));
    }

    public async Task<ServiceResult<GovernorateDetailsDto>> CreateAsync(string ownerUserId, CreateGovernorateDto dto)
    {
        logger.LogInformation("Creating governorate {GovernorateName} for user {UserId}", dto.Name, ownerUserId);

        var repo = unitOfWork.Repository<Governorate, int>();
        var governorate = new Governorate
        {
            // A caller can never create a locked/global row — only the dev seeder does that.
            OwnerUserId = ownerUserId,
            IsLocked = false,
            Name = dto.Name,
            NameAr = dto.NameAr
        };

        await repo.AddAsync(governorate);
        await unitOfWork.SaveChangesAsync();

        return ServiceResult<GovernorateDetailsDto>.Created(mapper.Map<GovernorateDetailsDto>(governorate));
    }

    public async Task<ServiceResult<GovernorateDetailsDto>> UpdateAsync(string ownerUserId, UpdateGovernorateDto dto)
    {
        var repo = unitOfWork.Repository<Governorate, int>();
        var governorate = await repo.GetByIdWithSpecAsync(new GovernorateWithSpecs(dto.Id, ownerUserId));

        if (governorate is null)
        {
            logger.LogWarning("Governorate {GovernorateId} not visible to user {UserId}", dto.Id, ownerUserId);
            return ServiceResult<GovernorateDetailsDto>.NotFound(localizer["Governorate.NotFound"], ErrorCodes.NotFound);
        }

        var lockedOrUnowned = CheckEditable(governorate, ownerUserId);
        if (lockedOrUnowned is not null)
        {
            return ServiceResult<GovernorateDetailsDto>.Conflict(lockedOrUnowned.Message!, lockedOrUnowned.ErrorCode!);
        }

        if (dto.Name is not null)
        {
            governorate.Name = dto.Name;
        }

        if (dto.NameAr is not null)
        {
            governorate.NameAr = dto.NameAr;
        }

        governorate.UpdatedAt = DateTime.UtcNow;
        repo.Update(governorate);
        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("Governorate {GovernorateId} updated for user {UserId}", dto.Id, ownerUserId);
        return ServiceResult<GovernorateDetailsDto>.Ok(mapper.Map<GovernorateDetailsDto>(governorate));
    }

    public async Task<ServiceResult> DeleteAsync(string ownerUserId, int id)
    {
        var repo = unitOfWork.Repository<Governorate, int>();
        var governorate = await repo.GetByIdWithSpecAsync(new GovernorateWithSpecs(id, ownerUserId));

        if (governorate is null)
        {
            logger.LogWarning("Governorate {GovernorateId} not visible to user {UserId}", id, ownerUserId);
            return ServiceResult.NotFound(localizer["Governorate.NotFound"], ErrorCodes.NotFound);
        }

        var lockedOrUnowned = CheckEditable(governorate, ownerUserId);
        if (lockedOrUnowned is not null)
        {
            return ServiceResult.Conflict(lockedOrUnowned.Message!, lockedOrUnowned.ErrorCode!);
        }

        var cityRepo = unitOfWork.Repository<City, int>();
        var activeCityCount = await cityRepo.CountWithSpecAsync(new CityWithSpecs(ownerUserId, id));
        if (activeCityCount > 0)
        {
            logger.LogWarning("Delete blocked for governorate {GovernorateId} — {Count} active cities still assigned", id, activeCityCount);
            return ServiceResult.Conflict(localizer["Governorate.HasActiveCities"], ErrorCodes.HasActiveCities);
        }

        var personRepo = unitOfWork.Repository<Person, int>();
        var activePersonCount = await personRepo.CountWithSpecAsync(PersonWithSpecs.ForGovernorate(ownerUserId, id));
        if (activePersonCount > 0)
        {
            logger.LogWarning("Delete blocked for governorate {GovernorateId} — {Count} active persons still assigned", id, activePersonCount);
            return ServiceResult.Conflict(localizer["Governorate.HasActivePersons"], ErrorCodes.HasActivePersons);
        }

        governorate.DeletedAt = DateTime.UtcNow;
        governorate.UpdatedAt = DateTime.UtcNow;
        repo.Update(governorate);
        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("Governorate {GovernorateId} soft-deleted for user {UserId}", id, ownerUserId);
        return ServiceResult.Ok("Governorate deleted successfully.");
    }

    // Returns a non-null "reason" result when editing is blocked (locked seeded row, or — as
    // defense in depth — a non-locked row that somehow isn't the caller's own); null means OK.
    // GovernorateWithSpecs already only ever resolves global-or-mine rows, so the NotOwned branch
    // is structurally unreachable today, but it keeps the invariant explicit rather than relying
    // on IsLocked alone if the spec's visibility rule ever changes.
    private ServiceResult<object>? CheckEditable(Governorate governorate, string ownerUserId)
    {
        if (governorate.IsLocked)
        {
            logger.LogWarning("Edit blocked for locked governorate {GovernorateId}", governorate.Id);
            return ServiceResult<object>.Conflict(localizer["Governorate.Locked"], ErrorCodes.Locked);
        }

        if (governorate.OwnerUserId != ownerUserId)
        {
            logger.LogWarning("Edit blocked for governorate {GovernorateId} — not owned by user {UserId}", governorate.Id, ownerUserId);
            return ServiceResult<object>.Conflict(localizer["Governorate.NotOwned"], ErrorCodes.NotOwned);
        }

        return null;
    }
}
