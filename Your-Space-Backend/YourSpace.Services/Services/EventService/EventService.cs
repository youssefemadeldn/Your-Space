using AutoMapper;
using Microsoft.Extensions.Localization;
using Microsoft.Extensions.Logging;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications.EventSpecifications;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Resources;
using YourSpace.Services.Services.EventService.Dtos;

namespace YourSpace.Services.Services.EventService;

public class EventService(
    IUnitOfWork unitOfWork,
    IMapper mapper,
    IStringLocalizer<SharedResource> localizer,
    ILogger<EventService> logger) : IEventService
{
    private static class ErrorCodes
    {
        public const string NotFound = "Event.NotFound";
    }

    public async Task<ServiceResult<EventDetailsDto>> GetDetailsAsync(string ownerUserId, int id)
    {
        var repo = unitOfWork.Repository<Event, int>();
        var @event = await repo.GetByIdWithSpecAsync(new EventWithSpecs(id, ownerUserId));

        if (@event is null)
        {
            logger.LogWarning("Event {EventId} not found for user {UserId}", id, ownerUserId);
            return ServiceResult<EventDetailsDto>.NotFound(localizer["Event.NotFound"], ErrorCodes.NotFound);
        }

        var dto = mapper.Map<EventDetailsDto>(@event);
        var guestRepo = unitOfWork.Repository<EventGuest, int>();
        var guests = await guestRepo.ListAllWithSpecAsync(EventGuestWithSpecs.ForEvent(@event.Id, ownerUserId));

        dto.TotalGuestCount = guests.Count;
        dto.NotInvitedCount = guests.Count(g => g.Status == EventGuestStatus.NotInvited);
        dto.InvitedCount = guests.Count(g => g.Status == EventGuestStatus.Invited);
        dto.SkippedCount = guests.Count(g => g.Status == EventGuestStatus.Skipped);

        return ServiceResult<EventDetailsDto>.Ok(dto);
    }

    public async Task<ServiceResult<PaginatedResultDto<EventProfileDto>>> GetAllAsync(string ownerUserId, string? search, PaginationSpecification pagination)
    {
        logger.LogInformation("Fetching events for user {UserId}", ownerUserId);

        var repo = unitOfWork.Repository<Event, int>();
        var totalItems = await repo.CountWithSpecAsync(new EventWithSpecs(ownerUserId, search));
        var events = await repo.ListAllWithSpecAsync(new EventWithSpecs(ownerUserId, search, pagination));

        // Single upfront query for every event's guest count on this page, grouped in C# —
        // avoids one CountWithSpecAsync round-trip per event (up to MaxPageSize).
        var eventIds = events.Select(e => e.Id).ToList();
        var guestRepo = unitOfWork.Repository<EventGuest, int>();
        var guestCountsByEventId = eventIds.Count == 0
            ? []
            : (await guestRepo.ListAllWithSpecAsync(EventGuestWithSpecs.ForEvents(eventIds, ownerUserId)))
                .GroupBy(g => g.EventId)
                .ToDictionary(g => g.Key, g => g.Count());

        var items = events.Select(e =>
        {
            var dto = mapper.Map<EventProfileDto>(e);
            dto.TotalGuestCount = guestCountsByEventId.GetValueOrDefault(e.Id);
            return dto;
        }).ToList();

        var totalPages = (int)Math.Ceiling(totalItems / (double)pagination.PageSize);

        return ServiceResult<PaginatedResultDto<EventProfileDto>>.Ok(
            new PaginatedResultDto<EventProfileDto>(items, pagination.PageIndex, pagination.PageSize, totalItems, totalPages));
    }

    public async Task<ServiceResult<EventDetailsDto>> CreateAsync(string ownerUserId, CreateEventDto dto)
    {
        logger.LogInformation("Creating event {EventName} for user {UserId}", dto.Name, ownerUserId);

        var repo = unitOfWork.Repository<Event, int>();
        var @event = new Event
        {
            OwnerUserId = ownerUserId,
            Name = dto.Name,
            NameAr = dto.NameAr,
            EventDate = dto.EventDate,
            Notes = dto.Notes
        };

        await repo.AddAsync(@event);
        await unitOfWork.SaveChangesAsync();

        var result = mapper.Map<EventDetailsDto>(@event);
        result.TotalGuestCount = 0;
        result.NotInvitedCount = 0;
        result.InvitedCount = 0;
        result.SkippedCount = 0;

        return ServiceResult<EventDetailsDto>.Created(result);
    }

    public async Task<ServiceResult<EventDetailsDto>> UpdateAsync(string ownerUserId, UpdateEventDto dto)
    {
        var repo = unitOfWork.Repository<Event, int>();
        var @event = await repo.GetByIdWithSpecAsync(new EventWithSpecs(dto.Id, ownerUserId));

        if (@event is null)
        {
            logger.LogWarning("Event {EventId} not found for user {UserId}", dto.Id, ownerUserId);
            return ServiceResult<EventDetailsDto>.NotFound(localizer["Event.NotFound"], ErrorCodes.NotFound);
        }

        if (dto.Name is not null)
        {
            @event.Name = dto.Name;
        }

        if (dto.NameAr is not null)
        {
            @event.NameAr = dto.NameAr;
        }

        if (dto.EventDate is not null)
        {
            @event.EventDate = dto.EventDate;
        }

        if (dto.Notes is not null)
        {
            @event.Notes = dto.Notes;
        }

        @event.UpdatedAt = DateTime.UtcNow;
        repo.Update(@event);
        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("Event {EventId} updated for user {UserId}", @event.Id, ownerUserId);

        var dtoResult = mapper.Map<EventDetailsDto>(@event);
        var guestRepo = unitOfWork.Repository<EventGuest, int>();
        var guests = await guestRepo.ListAllWithSpecAsync(EventGuestWithSpecs.ForEvent(@event.Id, ownerUserId));
        dtoResult.TotalGuestCount = guests.Count;
        dtoResult.NotInvitedCount = guests.Count(g => g.Status == EventGuestStatus.NotInvited);
        dtoResult.InvitedCount = guests.Count(g => g.Status == EventGuestStatus.Invited);
        dtoResult.SkippedCount = guests.Count(g => g.Status == EventGuestStatus.Skipped);

        return ServiceResult<EventDetailsDto>.Ok(dtoResult);
    }

    public async Task<ServiceResult> DeleteAsync(string ownerUserId, int id)
    {
        var repo = unitOfWork.Repository<Event, int>();
        var @event = await repo.GetByIdWithSpecAsync(new EventWithSpecs(id, ownerUserId));

        if (@event is null)
        {
            logger.LogWarning("Event {EventId} not found for user {UserId}", id, ownerUserId);
            return ServiceResult.NotFound(localizer["Event.NotFound"], ErrorCodes.NotFound);
        }

        @event.DeletedAt = DateTime.UtcNow;
        @event.UpdatedAt = DateTime.UtcNow;
        repo.Update(@event);
        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("Event {EventId} soft-deleted for user {UserId}", id, ownerUserId);
        return ServiceResult.Ok("Event deleted successfully.");
    }
}
