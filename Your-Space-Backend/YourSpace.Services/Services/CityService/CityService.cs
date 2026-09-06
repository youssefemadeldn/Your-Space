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
using YourSpace.Services.Services.CityService.Dtos;

namespace YourSpace.Services.Services.CityService;

public class CityService(
    IUnitOfWork unitOfWork,
    IMapper mapper,
    IStringLocalizer<SharedResource> localizer,
    ILogger<CityService> logger) : ICityService
{
    private static class ErrorCodes
    {
        public const string NotFound = "City.NotFound";
        public const string GovernorateNotFound = "City.GovernorateNotFound";
        public const string HasActiveNeighborhoods = "City.HasActiveNeighborhoods";
        public const string HasActivePersons = "City.HasActivePersons";
    }

    public async Task<ServiceResult<CityDetailsDto>> GetDetailsAsync(string ownerUserId, int governorateId, int id)
    {
        var repo = unitOfWork.Repository<City, int>();
        var city = await repo.GetByIdWithSpecAsync(new CityWithSpecs(id, governorateId, ownerUserId));

        if (city is null)
        {
            logger.LogWarning("City {CityId} not found for governorate {GovernorateId}, user {UserId}", id, governorateId, ownerUserId);
            return ServiceResult<CityDetailsDto>.NotFound(localizer["City.NotFound"], ErrorCodes.NotFound);
        }

        return ServiceResult<CityDetailsDto>.Ok(mapper.Map<CityDetailsDto>(city));
    }

    public async Task<ServiceResult<PaginatedResultDto<CityProfileDto>>> GetAllAsync(
        string ownerUserId, int governorateId, string? search, PaginationSpecification pagination)
    {
        logger.LogInformation("Fetching cities for governorate {GovernorateId}, user {UserId}", governorateId, ownerUserId);

        var repo = unitOfWork.Repository<City, int>();
        var totalItems = await repo.CountWithSpecAsync(new CityWithSpecs(ownerUserId, governorateId, search));
        var cities = await repo.ListAllWithSpecAsync(new CityWithSpecs(ownerUserId, governorateId, search, pagination));

        var neighborhoodRepo = unitOfWork.Repository<Neighborhood, int>();
        var allNeighborhoods = await neighborhoodRepo.ListAllWithSpecAsync(new NeighborhoodWithSpecs(ownerUserId));
        var neighborhoodCountByCity = allNeighborhoods.GroupBy(n => n.CityId).ToDictionary(g => g.Key, g => g.Count());

        var personRepo = unitOfWork.Repository<Person, int>();
        var allPersons = await personRepo.ListAllWithSpecAsync(new PersonWithSpecs(ownerUserId, (int?)null, (string?)null));
        var personCountByCity = allPersons
            .Where(p => p.CityId is not null)
            .GroupBy(p => p.CityId!.Value)
            .ToDictionary(g => g.Key, g => g.Count());

        var items = cities.Select(c =>
        {
            var dto = mapper.Map<CityProfileDto>(c);
            dto.NeighborhoodCount = neighborhoodCountByCity.GetValueOrDefault(c.Id, 0);
            dto.PersonCount = personCountByCity.GetValueOrDefault(c.Id, 0);
            return dto;
        }).ToList();

        var totalPages = (int)Math.Ceiling(totalItems / (double)pagination.PageSize);
        return ServiceResult<PaginatedResultDto<CityProfileDto>>.Ok(
            new PaginatedResultDto<CityProfileDto>(items, pagination.PageIndex, pagination.PageSize, totalItems, totalPages));
    }

    public async Task<ServiceResult<CityDetailsDto>> CreateAsync(string ownerUserId, int governorateId, CreateCityDto dto)
    {
        // A locked/global governorate is still a valid parent for a user's own City — only the
        // Governorate row itself is locked, not what users can attach underneath it.
        var governorateRepo = unitOfWork.Repository<Governorate, int>();
        var governorate = await governorateRepo.GetByIdWithSpecAsync(new GovernorateWithSpecs(governorateId, ownerUserId));
        if (governorate is null)
        {
            logger.LogWarning("Create city failed — governorate {GovernorateId} not visible to user {UserId}", governorateId, ownerUserId);
            return ServiceResult<CityDetailsDto>.NotFound(localizer["City.GovernorateNotFound"], ErrorCodes.GovernorateNotFound);
        }

        logger.LogInformation("Creating city {CityName} for governorate {GovernorateId}, user {UserId}", dto.Name, governorateId, ownerUserId);

        var repo = unitOfWork.Repository<City, int>();
        var city = new City
        {
            OwnerUserId = ownerUserId,
            GovernorateId = governorateId,
            Name = dto.Name,
            NameAr = dto.NameAr
        };

        await repo.AddAsync(city);
        await unitOfWork.SaveChangesAsync();

        return ServiceResult<CityDetailsDto>.Created(mapper.Map<CityDetailsDto>(city));
    }

    public async Task<ServiceResult<CityDetailsDto>> UpdateAsync(string ownerUserId, int governorateId, int id, UpdateCityDto dto)
    {
        var repo = unitOfWork.Repository<City, int>();
        var city = await repo.GetByIdWithSpecAsync(new CityWithSpecs(id, governorateId, ownerUserId));

        if (city is null)
        {
            logger.LogWarning("City {CityId} not found for governorate {GovernorateId}, user {UserId}", id, governorateId, ownerUserId);
            return ServiceResult<CityDetailsDto>.NotFound(localizer["City.NotFound"], ErrorCodes.NotFound);
        }

        if (dto.Name is not null)
        {
            city.Name = dto.Name;
        }

        if (dto.NameAr is not null)
        {
            city.NameAr = dto.NameAr;
        }

        city.UpdatedAt = DateTime.UtcNow;
        repo.Update(city);
        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("City {CityId} updated for governorate {GovernorateId}, user {UserId}", id, governorateId, ownerUserId);
        return ServiceResult<CityDetailsDto>.Ok(mapper.Map<CityDetailsDto>(city));
    }

    public async Task<ServiceResult> DeleteAsync(string ownerUserId, int governorateId, int id)
    {
        var repo = unitOfWork.Repository<City, int>();
        var city = await repo.GetByIdWithSpecAsync(new CityWithSpecs(id, governorateId, ownerUserId));

        if (city is null)
        {
            logger.LogWarning("City {CityId} not found for governorate {GovernorateId}, user {UserId}", id, governorateId, ownerUserId);
            return ServiceResult.NotFound(localizer["City.NotFound"], ErrorCodes.NotFound);
        }

        var neighborhoodRepo = unitOfWork.Repository<Neighborhood, int>();
        var activeNeighborhoodCount = await neighborhoodRepo.CountWithSpecAsync(new NeighborhoodWithSpecs(ownerUserId, id));
        if (activeNeighborhoodCount > 0)
        {
            logger.LogWarning("Delete blocked for city {CityId} — {Count} active neighborhoods still assigned", id, activeNeighborhoodCount);
            return ServiceResult.Conflict(localizer["City.HasActiveNeighborhoods"], ErrorCodes.HasActiveNeighborhoods);
        }

        var personRepo = unitOfWork.Repository<Person, int>();
        var activePersonCount = await personRepo.CountWithSpecAsync(PersonWithSpecs.ForCity(ownerUserId, id));
        if (activePersonCount > 0)
        {
            logger.LogWarning("Delete blocked for city {CityId} — {Count} active persons still assigned", id, activePersonCount);
            return ServiceResult.Conflict(localizer["City.HasActivePersons"], ErrorCodes.HasActivePersons);
        }

        city.DeletedAt = DateTime.UtcNow;
        city.UpdatedAt = DateTime.UtcNow;
        repo.Update(city);
        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("City {CityId} soft-deleted for governorate {GovernorateId}, user {UserId}", id, governorateId, ownerUserId);
        return ServiceResult.Ok("City deleted successfully.");
    }
}
