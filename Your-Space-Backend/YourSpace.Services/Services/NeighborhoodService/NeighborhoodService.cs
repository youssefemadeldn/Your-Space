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
using YourSpace.Services.Services.NeighborhoodService.Dtos;

namespace YourSpace.Services.Services.NeighborhoodService;

public class NeighborhoodService(
    IUnitOfWork unitOfWork,
    IMapper mapper,
    IStringLocalizer<SharedResource> localizer,
    ILogger<NeighborhoodService> logger) : INeighborhoodService
{
    private static class ErrorCodes
    {
        public const string NotFound = "Neighborhood.NotFound";
        public const string CityNotFound = "Neighborhood.CityNotFound";
        public const string HasActivePersons = "Neighborhood.HasActivePersons";
    }

    public async Task<ServiceResult<NeighborhoodDetailsDto>> GetDetailsAsync(string ownerUserId, int cityId, int id)
    {
        var repo = unitOfWork.Repository<Neighborhood, int>();
        var neighborhood = await repo.GetByIdWithSpecAsync(new NeighborhoodWithSpecs(id, cityId, ownerUserId));

        if (neighborhood is null)
        {
            logger.LogWarning("Neighborhood {NeighborhoodId} not found for city {CityId}, user {UserId}", id, cityId, ownerUserId);
            return ServiceResult<NeighborhoodDetailsDto>.NotFound(localizer["Neighborhood.NotFound"], ErrorCodes.NotFound);
        }

        return ServiceResult<NeighborhoodDetailsDto>.Ok(mapper.Map<NeighborhoodDetailsDto>(neighborhood));
    }

    public async Task<ServiceResult<PaginatedResultDto<NeighborhoodProfileDto>>> GetAllAsync(
        string ownerUserId, int cityId, string? search, PaginationSpecification pagination)
    {
        logger.LogInformation("Fetching neighborhoods for city {CityId}, user {UserId}", cityId, ownerUserId);

        var repo = unitOfWork.Repository<Neighborhood, int>();
        var totalItems = await repo.CountWithSpecAsync(new NeighborhoodWithSpecs(ownerUserId, cityId, search));
        var neighborhoods = await repo.ListAllWithSpecAsync(new NeighborhoodWithSpecs(ownerUserId, cityId, search, pagination));

        var personRepo = unitOfWork.Repository<Person, int>();
        var allPersons = await personRepo.ListAllWithSpecAsync(new PersonWithSpecs(ownerUserId, (int?)null, (string?)null));
        var personCountByNeighborhood = allPersons
            .Where(p => p.NeighborhoodId is not null)
            .GroupBy(p => p.NeighborhoodId!.Value)
            .ToDictionary(g => g.Key, g => g.Count());

        var items = neighborhoods.Select(n =>
        {
            var dto = mapper.Map<NeighborhoodProfileDto>(n);
            dto.PersonCount = personCountByNeighborhood.GetValueOrDefault(n.Id, 0);
            return dto;
        }).ToList();

        var totalPages = (int)Math.Ceiling(totalItems / (double)pagination.PageSize);
        return ServiceResult<PaginatedResultDto<NeighborhoodProfileDto>>.Ok(
            new PaginatedResultDto<NeighborhoodProfileDto>(items, pagination.PageIndex, pagination.PageSize, totalItems, totalPages));
    }

    public async Task<ServiceResult<NeighborhoodDetailsDto>> CreateAsync(string ownerUserId, int cityId, CreateNeighborhoodDto dto)
    {
        var cityRepo = unitOfWork.Repository<City, int>();
        var city = await cityRepo.GetByIdWithSpecAsync(new CityWithSpecs(cityId, ownerUserId));
        if (city is null)
        {
            logger.LogWarning("Create neighborhood failed — city {CityId} not found for user {UserId}", cityId, ownerUserId);
            return ServiceResult<NeighborhoodDetailsDto>.NotFound(localizer["Neighborhood.CityNotFound"], ErrorCodes.CityNotFound);
        }

        logger.LogInformation("Creating neighborhood {NeighborhoodName} for city {CityId}, user {UserId}", dto.Name, cityId, ownerUserId);

        var repo = unitOfWork.Repository<Neighborhood, int>();
        var neighborhood = new Neighborhood
        {
            OwnerUserId = ownerUserId,
            CityId = cityId,
            Name = dto.Name,
            NameAr = dto.NameAr
        };

        await repo.AddAsync(neighborhood);
        await unitOfWork.SaveChangesAsync();

        return ServiceResult<NeighborhoodDetailsDto>.Created(mapper.Map<NeighborhoodDetailsDto>(neighborhood));
    }

    public async Task<ServiceResult<NeighborhoodDetailsDto>> UpdateAsync(string ownerUserId, int cityId, int id, UpdateNeighborhoodDto dto)
    {
        var repo = unitOfWork.Repository<Neighborhood, int>();
        var neighborhood = await repo.GetByIdWithSpecAsync(new NeighborhoodWithSpecs(id, cityId, ownerUserId));

        if (neighborhood is null)
        {
            logger.LogWarning("Neighborhood {NeighborhoodId} not found for city {CityId}, user {UserId}", id, cityId, ownerUserId);
            return ServiceResult<NeighborhoodDetailsDto>.NotFound(localizer["Neighborhood.NotFound"], ErrorCodes.NotFound);
        }

        if (dto.Name is not null)
        {
            neighborhood.Name = dto.Name;
        }

        if (dto.NameAr is not null)
        {
            neighborhood.NameAr = dto.NameAr;
        }

        neighborhood.UpdatedAt = DateTime.UtcNow;
        repo.Update(neighborhood);
        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("Neighborhood {NeighborhoodId} updated for city {CityId}, user {UserId}", id, cityId, ownerUserId);
        return ServiceResult<NeighborhoodDetailsDto>.Ok(mapper.Map<NeighborhoodDetailsDto>(neighborhood));
    }

    public async Task<ServiceResult> DeleteAsync(string ownerUserId, int cityId, int id)
    {
        var repo = unitOfWork.Repository<Neighborhood, int>();
        var neighborhood = await repo.GetByIdWithSpecAsync(new NeighborhoodWithSpecs(id, cityId, ownerUserId));

        if (neighborhood is null)
        {
            logger.LogWarning("Neighborhood {NeighborhoodId} not found for city {CityId}, user {UserId}", id, cityId, ownerUserId);
            return ServiceResult.NotFound(localizer["Neighborhood.NotFound"], ErrorCodes.NotFound);
        }

        var personRepo = unitOfWork.Repository<Person, int>();
        var activePersonCount = await personRepo.CountWithSpecAsync(PersonWithSpecs.ForNeighborhood(ownerUserId, id));
        if (activePersonCount > 0)
        {
            logger.LogWarning("Delete blocked for neighborhood {NeighborhoodId} — {Count} active persons still assigned", id, activePersonCount);
            return ServiceResult.Conflict(localizer["Neighborhood.HasActivePersons"], ErrorCodes.HasActivePersons);
        }

        neighborhood.DeletedAt = DateTime.UtcNow;
        neighborhood.UpdatedAt = DateTime.UtcNow;
        repo.Update(neighborhood);
        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("Neighborhood {NeighborhoodId} soft-deleted for city {CityId}, user {UserId}", id, cityId, ownerUserId);
        return ServiceResult.Ok("Neighborhood deleted successfully.");
    }
}
