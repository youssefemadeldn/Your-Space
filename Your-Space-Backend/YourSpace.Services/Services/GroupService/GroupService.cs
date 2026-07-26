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
using YourSpace.Services.Services.GroupService.Dtos;

namespace YourSpace.Services.Services.GroupService;

public class GroupService(
    IUnitOfWork unitOfWork,
    IMapper mapper,
    IStringLocalizer<SharedResource> localizer,
    ILogger<GroupService> logger) : IGroupService
{
    private static class ErrorCodes
    {
        public const string NotFound = "Group.NotFound";
        public const string HasActivePersons = "Group.HasActivePersons";
    }

    public async Task<ServiceResult<GroupDetailsDto>> GetDetailsAsync(string ownerUserId, int id)
    {
        var repo = unitOfWork.Repository<Group, int>();
        var group = await repo.GetByIdWithSpecAsync(new GroupWithSpecs(id, ownerUserId));

        if (group is null)
        {
            logger.LogWarning("Group {GroupId} not found for user {UserId}", id, ownerUserId);
            return ServiceResult<GroupDetailsDto>.NotFound(localizer["Group.NotFound"], ErrorCodes.NotFound);
        }

        return ServiceResult<GroupDetailsDto>.Ok(mapper.Map<GroupDetailsDto>(group));
    }

    public async Task<ServiceResult<PaginatedResultDto<GroupProfileDto>>> GetAllAsync(string ownerUserId, string? search, PaginationSpecification pagination)
    {
        logger.LogInformation("Fetching groups for user {UserId}", ownerUserId);

        var repo = unitOfWork.Repository<Group, int>();
        var totalItems = await repo.CountWithSpecAsync(new GroupWithSpecs(ownerUserId, search));
        var groups = await repo.ListAllWithSpecAsync(new GroupWithSpecs(ownerUserId, search, pagination));

        var items = groups.Select(mapper.Map<GroupProfileDto>).ToList();
        var totalPages = (int)Math.Ceiling(totalItems / (double)pagination.PageSize);

        return ServiceResult<PaginatedResultDto<GroupProfileDto>>.Ok(
            new PaginatedResultDto<GroupProfileDto>(items, pagination.PageIndex, pagination.PageSize, totalItems, totalPages));
    }

    public async Task<ServiceResult<GroupDetailsDto>> CreateAsync(string ownerUserId, CreateGroupDto dto)
    {
        logger.LogInformation("Creating group {GroupName} for user {UserId}", dto.Name, ownerUserId);

        var repo = unitOfWork.Repository<Group, int>();
        var group = new Group
        {
            OwnerUserId = ownerUserId,
            Name = dto.Name,
            NameAr = dto.NameAr
        };

        await repo.AddAsync(group);
        await unitOfWork.SaveChangesAsync();

        return ServiceResult<GroupDetailsDto>.Created(mapper.Map<GroupDetailsDto>(group));
    }

    public async Task<ServiceResult<GroupDetailsDto>> UpdateAsync(string ownerUserId, UpdateGroupDto dto)
    {
        var repo = unitOfWork.Repository<Group, int>();
        var group = await repo.GetByIdWithSpecAsync(new GroupWithSpecs(dto.Id, ownerUserId));

        if (group is null)
        {
            logger.LogWarning("Group {GroupId} not found for user {UserId}", dto.Id, ownerUserId);
            return ServiceResult<GroupDetailsDto>.NotFound(localizer["Group.NotFound"], ErrorCodes.NotFound);
        }

        if (dto.Name is not null)
        {
            group.Name = dto.Name;
        }

        if (dto.NameAr is not null)
        {
            group.NameAr = dto.NameAr;
        }

        group.UpdatedAt = DateTime.UtcNow;
        repo.Update(group);
        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("Group {GroupId} updated for user {UserId}", group.Id, ownerUserId);
        return ServiceResult<GroupDetailsDto>.Ok(mapper.Map<GroupDetailsDto>(group));
    }

    public async Task<ServiceResult> DeleteAsync(string ownerUserId, int id)
    {
        var repo = unitOfWork.Repository<Group, int>();
        var group = await repo.GetByIdWithSpecAsync(new GroupWithSpecs(id, ownerUserId));

        if (group is null)
        {
            logger.LogWarning("Group {GroupId} not found for user {UserId}", id, ownerUserId);
            return ServiceResult.NotFound(localizer["Group.NotFound"], ErrorCodes.NotFound);
        }

        // Domain invariant a validator can't see (DB-dependent) — a Group is master data
        // potentially referenced by many independent Persons; deleting it while active Persons
        // still point to it would silently strand their categorization.
        var personRepo = unitOfWork.Repository<Person, int>();
        var activePersonCount = await personRepo.CountWithSpecAsync(new PersonWithSpecs(ownerUserId, id, null));
        if (activePersonCount > 0)
        {
            logger.LogWarning("Delete blocked for group {GroupId} — {Count} active persons still assigned", id, activePersonCount);
            return ServiceResult.Conflict(localizer["Group.HasActivePersons"], ErrorCodes.HasActivePersons);
        }

        group.DeletedAt = DateTime.UtcNow;
        group.UpdatedAt = DateTime.UtcNow;
        repo.Update(group);
        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("Group {GroupId} soft-deleted for user {UserId}", id, ownerUserId);
        return ServiceResult.Ok("Group deleted successfully.");
    }
}
