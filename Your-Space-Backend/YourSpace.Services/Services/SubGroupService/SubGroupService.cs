using AutoMapper;
using Microsoft.Extensions.Localization;
using Microsoft.Extensions.Logging;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications.GroupSpecifications;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Repository.Specifications.PeopleSpecifications;
using YourSpace.Repository.Sync;
using YourSpace.Services.Helper;
using YourSpace.Services.Resources;
using YourSpace.Services.Services.SubGroupService.Dtos;

namespace YourSpace.Services.Services.SubGroupService;

public class SubGroupService(
    IUnitOfWork unitOfWork,
    IMapper mapper,
    IStringLocalizer<SharedResource> localizer,
    ISyncVersionProvider syncVersionProvider,
    ILogger<SubGroupService> logger) : ISubGroupService
{
    // Postgres sequence backing SubGroup.SyncVersion (doc/local-first-sync-design.md §6) — one
    // per synced entity table, bumped explicitly on every create/update/soft-delete since a
    // bigserial-style column only auto-populates on INSERT, never on UPDATE.
    private const string SyncVersionSequenceName = "SubGroups_SyncVersion_seq";

    // Defensive cap on GetChangesAsync's pageSize — this data shape is "small, low cardinality"
    // (design doc §1/§2), never expected to need a larger page.
    private const int MaxChangesPageSize = 500;

    private static class ErrorCodes
    {
        public const string NotFound = "SubGroup.NotFound";
        public const string GroupNotFound = "SubGroup.GroupNotFound";
        public const string HasActivePersons = "SubGroup.HasActivePersons";
        public const string SinceInvalid = "SubGroup.Since.Invalid";
    }

    public async Task<ServiceResult<SubGroupDetailsDto>> GetDetailsAsync(string ownerUserId, int groupId, int id)
    {
        var repo = unitOfWork.Repository<SubGroup, int>();
        var subGroup = await repo.GetByIdWithSpecAsync(new SubGroupWithSpecs(id, groupId, ownerUserId));

        if (subGroup is null)
        {
            logger.LogWarning("SubGroup {SubGroupId} not found for group {GroupId}, user {UserId}", id, groupId, ownerUserId);
            return ServiceResult<SubGroupDetailsDto>.NotFound(localizer["SubGroup.NotFound"], ErrorCodes.NotFound);
        }

        return ServiceResult<SubGroupDetailsDto>.Ok(mapper.Map<SubGroupDetailsDto>(subGroup));
    }

    public async Task<ServiceResult<PaginatedResultDto<SubGroupProfileDto>>> GetAllAsync(
        string ownerUserId, int groupId, string? search, PaginationSpecification pagination)
    {
        logger.LogInformation("Fetching subgroups for group {GroupId}, user {UserId}", groupId, ownerUserId);

        var repo = unitOfWork.Repository<SubGroup, int>();
        var totalItems = await repo.CountWithSpecAsync(new SubGroupWithSpecs(ownerUserId, groupId, search));
        var subGroups = await repo.ListAllWithSpecAsync(new SubGroupWithSpecs(ownerUserId, groupId, search, pagination));

        var personRepo = unitOfWork.Repository<Person, int>();
        var personsInGroup = await personRepo.ListAllWithSpecAsync(new PersonWithSpecs(ownerUserId, groupId));
        var countBySubGroup = personsInGroup
            .Where(p => p.SubGroupId is not null)
            .GroupBy(p => p.SubGroupId!.Value)
            .ToDictionary(g => g.Key, g => g.Count());

        var items = subGroups.Select(s =>
        {
            var dto = mapper.Map<SubGroupProfileDto>(s);
            dto.PersonCount = countBySubGroup.GetValueOrDefault(s.Id, 0);
            return dto;
        }).ToList();

        var totalPages = (int)Math.Ceiling(totalItems / (double)pagination.PageSize);
        return ServiceResult<PaginatedResultDto<SubGroupProfileDto>>.Ok(
            new PaginatedResultDto<SubGroupProfileDto>(items, pagination.PageIndex, pagination.PageSize, totalItems, totalPages));
    }

    public async Task<ServiceResult<PaginatedResultDto<SubGroupProfileDto>>> GetAllMineAsync(
        string ownerUserId, string? search, PaginationSpecification pagination)
    {
        logger.LogInformation("Fetching all subgroups for user {UserId} (flat, group-agnostic)", ownerUserId);

        var repo = unitOfWork.Repository<SubGroup, int>();
        var totalItems = await repo.CountWithSpecAsync(new SubGroupWithSpecs(ownerUserId, search));
        var subGroups = await repo.ListAllWithSpecAsync(new SubGroupWithSpecs(ownerUserId, search, pagination));

        // No PersonCount enrichment here — this feeds the mobile Tier 1 bulk sync (design doc
        // §11 row 8.14), which never reads it (server-computed, not cached locally, design doc
        // §8). The richer nested GetAllAsync above keeps computing it for the management screen.
        var items = subGroups.Select(mapper.Map<SubGroupProfileDto>).ToList();

        var totalPages = (int)Math.Ceiling(totalItems / (double)pagination.PageSize);
        return ServiceResult<PaginatedResultDto<SubGroupProfileDto>>.Ok(
            new PaginatedResultDto<SubGroupProfileDto>(items, pagination.PageIndex, pagination.PageSize, totalItems, totalPages));
    }

    public async Task<ServiceResult<SubGroupDetailsDto>> CreateAsync(string ownerUserId, int groupId, CreateSubGroupDto dto)
    {
        var groupRepo = unitOfWork.Repository<Group, int>();
        var group = await groupRepo.GetByIdWithSpecAsync(new GroupWithSpecs(groupId, ownerUserId));
        if (group is null)
        {
            logger.LogWarning("Create subgroup failed — group {GroupId} not found for user {UserId}", groupId, ownerUserId);
            return ServiceResult<SubGroupDetailsDto>.NotFound(localizer["SubGroup.GroupNotFound"], ErrorCodes.GroupNotFound);
        }

        logger.LogInformation("Creating subgroup {SubGroupName} for group {GroupId}, user {UserId}", dto.Name, groupId, ownerUserId);

        var repo = unitOfWork.Repository<SubGroup, int>();
        var subGroup = new SubGroup
        {
            OwnerUserId = ownerUserId,
            GroupId = groupId,
            Name = dto.Name,
            NameAr = dto.NameAr,
            SyncVersion = await syncVersionProvider.NextValueAsync(SyncVersionSequenceName)
        };

        await repo.AddAsync(subGroup);
        await unitOfWork.SaveChangesAsync();

        return ServiceResult<SubGroupDetailsDto>.Created(mapper.Map<SubGroupDetailsDto>(subGroup));
    }

    public async Task<ServiceResult<SubGroupDetailsDto>> UpdateAsync(string ownerUserId, int groupId, int id, UpdateSubGroupDto dto)
    {
        var repo = unitOfWork.Repository<SubGroup, int>();
        var subGroup = await repo.GetByIdWithSpecAsync(new SubGroupWithSpecs(id, groupId, ownerUserId));

        if (subGroup is null)
        {
            logger.LogWarning("SubGroup {SubGroupId} not found for group {GroupId}, user {UserId}", id, groupId, ownerUserId);
            return ServiceResult<SubGroupDetailsDto>.NotFound(localizer["SubGroup.NotFound"], ErrorCodes.NotFound);
        }

        if (dto.Name is not null)
        {
            subGroup.Name = dto.Name;
        }

        if (dto.NameAr is not null)
        {
            subGroup.NameAr = dto.NameAr;
        }

        subGroup.UpdatedAt = DateTime.UtcNow;
        subGroup.SyncVersion = await syncVersionProvider.NextValueAsync(SyncVersionSequenceName);
        repo.Update(subGroup);
        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("SubGroup {SubGroupId} updated for group {GroupId}, user {UserId}", id, groupId, ownerUserId);
        return ServiceResult<SubGroupDetailsDto>.Ok(mapper.Map<SubGroupDetailsDto>(subGroup));
    }

    public async Task<ServiceResult> DeleteAsync(string ownerUserId, int groupId, int id)
    {
        var repo = unitOfWork.Repository<SubGroup, int>();
        var subGroup = await repo.GetByIdWithSpecAsync(new SubGroupWithSpecs(id, groupId, ownerUserId));

        if (subGroup is null)
        {
            logger.LogWarning("SubGroup {SubGroupId} not found for group {GroupId}, user {UserId}", id, groupId, ownerUserId);
            return ServiceResult.NotFound(localizer["SubGroup.NotFound"], ErrorCodes.NotFound);
        }

        var personRepo = unitOfWork.Repository<Person, int>();
        var activePersonCount = await personRepo.CountWithSpecAsync(PersonWithSpecs.ForSubGroup(ownerUserId, id));
        if (activePersonCount > 0)
        {
            logger.LogWarning("Delete blocked for subgroup {SubGroupId} — {Count} active persons still assigned", id, activePersonCount);
            return ServiceResult.Conflict(localizer["SubGroup.HasActivePersons"], ErrorCodes.HasActivePersons);
        }

        subGroup.DeletedAt = DateTime.UtcNow;
        subGroup.UpdatedAt = DateTime.UtcNow;
        subGroup.SyncVersion = await syncVersionProvider.NextValueAsync(SyncVersionSequenceName);
        repo.Update(subGroup);
        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("SubGroup {SubGroupId} soft-deleted for group {GroupId}, user {UserId}", id, groupId, ownerUserId);
        return ServiceResult.Ok("Subgroup deleted successfully.");
    }

    public async Task<ServiceResult<SubGroupChangesDto>> GetChangesAsync(string ownerUserId, long since, int pageSize)
    {
        if (since < 0)
        {
            logger.LogWarning("GetChanges rejected — negative since {Since} for user {UserId}", since, ownerUserId);
            return ServiceResult<SubGroupChangesDto>.Fail(localizer["SubGroup.Since.Invalid"], ErrorCodes.SinceInvalid);
        }

        var clampedPageSize = Math.Clamp(pageSize, 1, MaxChangesPageSize);

        var repo = unitOfWork.Repository<SubGroup, int>();
        var rows = await repo.ListAllWithSpecAsync(new SubGroupWithSpecs(ownerUserId, since, clampedPageSize));

        var upsertRows = rows.Where(s => s.DeletedAt == null).ToList();
        var tombstoneIds = rows.Where(s => s.DeletedAt != null).Select(s => s.Id).ToList();

        var upserts = upsertRows.Select(mapper.Map<SubGroupProfileDto>).ToList();

        var cursor = rows.Count > 0 ? rows.Max(s => s.SyncVersion) : since;
        var hasMore = rows.Count == clampedPageSize;

        return ServiceResult<SubGroupChangesDto>.Ok(new SubGroupChangesDto
        {
            Upserts = upserts,
            TombstoneIds = tombstoneIds,
            Cursor = cursor,
            HasMore = hasMore
        });
    }
}
