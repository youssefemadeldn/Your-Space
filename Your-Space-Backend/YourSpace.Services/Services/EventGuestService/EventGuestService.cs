using AutoMapper;
using Microsoft.Extensions.Localization;
using Microsoft.Extensions.Logging;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications.EventSpecifications;
using YourSpace.Repository.Specifications.GroupSpecifications;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Repository.Specifications.PeopleSpecifications;
using YourSpace.Services.Helper;
using YourSpace.Services.Resources;
using YourSpace.Services.Services.EventGuestService.Dtos;
using YourSpace.Services.Services.PersonService.Dtos;

namespace YourSpace.Services.Services.EventGuestService;

public class EventGuestService(
    IUnitOfWork unitOfWork,
    IMapper mapper,
    IStringLocalizer<SharedResource> localizer,
    ILogger<EventGuestService> logger) : IEventGuestService
{
    private static class ErrorCodes
    {
        public const string NotFound = "EventGuest.NotFound";
        public const string EventNotFound = "EventGuest.EventNotFound";
        public const string PersonNotFound = "EventGuest.PersonNotFound";
        public const string GroupNotFound = "EventGuest.GroupNotFound";
    }

    public async Task<ServiceResult<EventGuestDetailsDto>> GetDetailsAsync(string ownerUserId, int eventId, int guestId)
    {
        var repo = unitOfWork.Repository<EventGuest, int>();
        var guest = await repo.GetByIdWithSpecAsync(EventGuestWithSpecs.ById(guestId, eventId, ownerUserId));

        if (guest is null)
        {
            logger.LogWarning("Guest {GuestId} not found for event {EventId}, user {UserId}", guestId, eventId, ownerUserId);
            return ServiceResult<EventGuestDetailsDto>.NotFound(localizer["EventGuest.NotFound"], ErrorCodes.NotFound);
        }

        return ServiceResult<EventGuestDetailsDto>.Ok(BuildDetailsDto(guest));
    }

    public async Task<ServiceResult<PaginatedResultDto<EventGuestProfileDto>>> GetListAsync(
        string ownerUserId, int eventId, int? groupId, EventGuestStatus? status, PaginationSpecification pagination)
    {
        if (!await EventExistsAsync(eventId, ownerUserId))
        {
            return ServiceResult<PaginatedResultDto<EventGuestProfileDto>>.NotFound(localizer["EventGuest.EventNotFound"], ErrorCodes.EventNotFound);
        }

        var repo = unitOfWork.Repository<EventGuest, int>();
        var totalItems = await repo.CountWithSpecAsync(new EventGuestWithSpecs(eventId, ownerUserId, groupId, status));
        var guests = await repo.ListAllWithSpecAsync(new EventGuestWithSpecs(eventId, ownerUserId, groupId, status, pagination));

        var items = guests.Select(BuildProfileDto).ToList();
        var totalPages = (int)Math.Ceiling(totalItems / (double)pagination.PageSize);

        return ServiceResult<PaginatedResultDto<EventGuestProfileDto>>.Ok(
            new PaginatedResultDto<EventGuestProfileDto>(items, pagination.PageIndex, pagination.PageSize, totalItems, totalPages));
    }

    public async Task<ServiceResult<EventGuestProgressSummaryDto>> GetProgressAsync(string ownerUserId, int eventId)
    {
        if (!await EventExistsAsync(eventId, ownerUserId))
        {
            return ServiceResult<EventGuestProgressSummaryDto>.NotFound(localizer["EventGuest.EventNotFound"], ErrorCodes.EventNotFound);
        }

        var groupRepo = unitOfWork.Repository<Group, int>();
        var groups = await groupRepo.ListAllWithSpecAsync(new GroupWithSpecs(ownerUserId));

        var personRepo = unitOfWork.Repository<Person, int>();
        var allPersons = await personRepo.ListAllWithSpecAsync(new PersonWithSpecs(ownerUserId, (int?)null, (string?)null));

        var guestRepo = unitOfWork.Repository<EventGuest, int>();
        var guests = await guestRepo.ListAllWithSpecAsync(EventGuestWithSpecs.ForEvent(eventId, ownerUserId));

        // Every group appears here, even ones with zero guests added to this event yet — the
        // client needs to see "haven't started this group" the same as "finished this group".
        var groupProgress = groups.Select(group =>
        {
            var guestsInGroup = guests.Where(g => g.Person.GroupId == group.Id).ToList();
            return new GroupGuestProgressDto
            {
                GroupId = group.Id,
                GroupName = LocalizedTextResolver.Resolve(group.Name, group.NameAr),
                TotalPersonsInGroup = allPersons.Count(p => p.GroupId == group.Id),
                GuestsAddedCount = guestsInGroup.Count,
                NotInvitedCount = guestsInGroup.Count(g => g.Status == EventGuestStatus.NotInvited),
                InvitedCount = guestsInGroup.Count(g => g.Status == EventGuestStatus.Invited),
                SkippedCount = guestsInGroup.Count(g => g.Status == EventGuestStatus.Skipped)
            };
        }).ToList();

        var summary = new EventGuestProgressSummaryDto
        {
            EventId = eventId,
            TotalGuestCount = guests.Count,
            NotInvitedCount = guests.Count(g => g.Status == EventGuestStatus.NotInvited),
            InvitedCount = guests.Count(g => g.Status == EventGuestStatus.Invited),
            SkippedCount = guests.Count(g => g.Status == EventGuestStatus.Skipped),
            Groups = groupProgress
        };

        return ServiceResult<EventGuestProgressSummaryDto>.Ok(summary);
    }

    public async Task<ServiceResult<PaginatedResultDto<PersonProfileDto>>> GetReciprocitySuggestionsAsync(
        string ownerUserId, int eventId, int? groupId, PaginationSpecification pagination)
    {
        if (!await EventExistsAsync(eventId, ownerUserId))
        {
            return ServiceResult<PaginatedResultDto<PersonProfileDto>>.NotFound(localizer["EventGuest.EventNotFound"], ErrorCodes.EventNotFound);
        }

        var historyRepo = unitOfWork.Repository<PersonOccasionHistory, int>();
        var history = await historyRepo.ListAllWithSpecAsync(PersonOccasionHistoryWithSpecs.ReciprocityCandidates(ownerUserId));
        var candidateIds = history.Select(h => h.PersonId).Distinct().ToList();

        var guestRepo = unitOfWork.Repository<EventGuest, int>();
        var existingGuests = await guestRepo.ListAllWithSpecAsync(EventGuestWithSpecs.ForEvent(eventId, ownerUserId));
        var alreadyAddedIds = existingGuests.Select(g => g.PersonId).ToHashSet();

        candidateIds = candidateIds.Where(id => !alreadyAddedIds.Contains(id)).ToList();

        if (candidateIds.Count == 0)
        {
            return ServiceResult<PaginatedResultDto<PersonProfileDto>>.Ok(
                new PaginatedResultDto<PersonProfileDto>([], pagination.PageIndex, pagination.PageSize, 0, 0));
        }

        var personRepo = unitOfWork.Repository<Person, int>();
        var candidates = await personRepo.ListAllWithSpecAsync(new PersonWithSpecs(ownerUserId, candidateIds, groupId));

        // Small candidate set at personal-event scale — paginating in memory here avoids adding a
        // paginated overload to the explicit-id-list specification for a rarely-large result set.
        var totalItems = candidates.Count;
        var pageItems = candidates
            .OrderBy(p => p.Name)
            .Skip(pagination.PageSize * (pagination.PageIndex - 1))
            .Take(pagination.PageSize)
            .Select(p =>
            {
                var dto = mapper.Map<PersonProfileDto>(p);
                dto.HasReciprocityHistory = true;
                return dto;
            })
            .ToList();

        var totalPages = (int)Math.Ceiling(totalItems / (double)pagination.PageSize);

        return ServiceResult<PaginatedResultDto<PersonProfileDto>>.Ok(
            new PaginatedResultDto<PersonProfileDto>(pageItems, pagination.PageIndex, pagination.PageSize, totalItems, totalPages));
    }

    public async Task<ServiceResult<BulkAddGuestsResultDto>> AddPersonsAsync(string ownerUserId, int eventId, AddPersonsToEventDto dto)
    {
        if (!await EventExistsAsync(eventId, ownerUserId))
        {
            return ServiceResult<BulkAddGuestsResultDto>.NotFound(localizer["EventGuest.EventNotFound"], ErrorCodes.EventNotFound);
        }

        var requestedIds = dto.PersonIds.Distinct().ToList();

        var personRepo = unitOfWork.Repository<Person, int>();
        var validPersons = await personRepo.ListAllWithSpecAsync(new PersonWithSpecs(ownerUserId, requestedIds, null));
        if (validPersons.Count != requestedIds.Count)
        {
            logger.LogWarning("Add persons to event {EventId} failed — one or more person IDs invalid for user {UserId}", eventId, ownerUserId);
            return ServiceResult<BulkAddGuestsResultDto>.NotFound(localizer["EventGuest.PersonNotFound"], ErrorCodes.PersonNotFound);
        }

        return await AddGuestsAsync(ownerUserId, eventId, requestedIds);
    }

    public async Task<ServiceResult<BulkAddGuestsResultDto>> AddGroupAsync(string ownerUserId, int eventId, int groupId)
    {
        if (!await EventExistsAsync(eventId, ownerUserId))
        {
            return ServiceResult<BulkAddGuestsResultDto>.NotFound(localizer["EventGuest.EventNotFound"], ErrorCodes.EventNotFound);
        }

        var groupRepo = unitOfWork.Repository<Group, int>();
        var group = await groupRepo.GetByIdWithSpecAsync(new GroupWithSpecs(groupId, ownerUserId));
        if (group is null)
        {
            logger.LogWarning("Add group to event {EventId} failed — group {GroupId} not found for user {UserId}", eventId, groupId, ownerUserId);
            return ServiceResult<BulkAddGuestsResultDto>.NotFound(localizer["EventGuest.GroupNotFound"], ErrorCodes.GroupNotFound);
        }

        var personRepo = unitOfWork.Repository<Person, int>();
        var personsInGroup = await personRepo.ListAllWithSpecAsync(new PersonWithSpecs(ownerUserId, groupId));
        var personIds = personsInGroup.Select(p => p.Id).ToList();

        return await AddGuestsAsync(ownerUserId, eventId, personIds);
    }

    public async Task<ServiceResult<EventGuestDetailsDto>> MarkInvitedAsync(string ownerUserId, int eventId, int guestId, MarkGuestInvitedDto dto)
    {
        var repo = unitOfWork.Repository<EventGuest, int>();
        var guest = await repo.GetByIdWithSpecAsync(EventGuestWithSpecs.ById(guestId, eventId, ownerUserId));

        if (guest is null)
        {
            logger.LogWarning("Guest {GuestId} not found for event {EventId}, user {UserId}", guestId, eventId, ownerUserId);
            return ServiceResult<EventGuestDetailsDto>.NotFound(localizer["EventGuest.NotFound"], ErrorCodes.NotFound);
        }

        // Idempotent upsert, not a guarded transition — re-inviting an already-invited guest just
        // corrects the method, the simplest and most forgiving behavior for a personal tool.
        guest.Status = EventGuestStatus.Invited;
        guest.InviteMethod = dto.InviteMethod;
        guest.InvitedAt = DateTime.UtcNow;
        guest.UpdatedAt = DateTime.UtcNow;
        repo.Update(guest);
        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("Guest {GuestId} marked invited via {InviteMethod} for event {EventId}", guestId, dto.InviteMethod, eventId);
        return ServiceResult<EventGuestDetailsDto>.Ok(BuildDetailsDto(guest));
    }

    public async Task<ServiceResult<EventGuestDetailsDto>> MarkSkippedAsync(string ownerUserId, int eventId, int guestId)
    {
        var repo = unitOfWork.Repository<EventGuest, int>();
        var guest = await repo.GetByIdWithSpecAsync(EventGuestWithSpecs.ById(guestId, eventId, ownerUserId));

        if (guest is null)
        {
            logger.LogWarning("Guest {GuestId} not found for event {EventId}, user {UserId}", guestId, eventId, ownerUserId);
            return ServiceResult<EventGuestDetailsDto>.NotFound(localizer["EventGuest.NotFound"], ErrorCodes.NotFound);
        }

        guest.Status = EventGuestStatus.Skipped;
        guest.InviteMethod = null;
        guest.InvitedAt = null;
        guest.UpdatedAt = DateTime.UtcNow;
        repo.Update(guest);
        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("Guest {GuestId} marked skipped for event {EventId}", guestId, eventId);
        return ServiceResult<EventGuestDetailsDto>.Ok(BuildDetailsDto(guest));
    }

    public async Task<ServiceResult<EventGuestDetailsDto>> RevertAsync(string ownerUserId, int eventId, int guestId)
    {
        var repo = unitOfWork.Repository<EventGuest, int>();
        var guest = await repo.GetByIdWithSpecAsync(EventGuestWithSpecs.ById(guestId, eventId, ownerUserId));

        if (guest is null)
        {
            logger.LogWarning("Guest {GuestId} not found for event {EventId}, user {UserId}", guestId, eventId, ownerUserId);
            return ServiceResult<EventGuestDetailsDto>.NotFound(localizer["EventGuest.NotFound"], ErrorCodes.NotFound);
        }

        // A no-op when already NotInvited — reverting is idempotent, same as invite/skip.
        guest.Status = EventGuestStatus.NotInvited;
        guest.InviteMethod = null;
        guest.InvitedAt = null;
        guest.UpdatedAt = DateTime.UtcNow;
        repo.Update(guest);
        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("Guest {GuestId} reverted to not-invited for event {EventId}", guestId, eventId);
        return ServiceResult<EventGuestDetailsDto>.Ok(BuildDetailsDto(guest));
    }

    public async Task<ServiceResult> RemoveGuestAsync(string ownerUserId, int eventId, int guestId)
    {
        var repo = unitOfWork.Repository<EventGuest, int>();
        var guest = await repo.GetByIdWithSpecAsync(EventGuestWithSpecs.ById(guestId, eventId, ownerUserId));

        if (guest is null)
        {
            logger.LogWarning("Guest {GuestId} not found for event {EventId}, user {UserId}", guestId, eventId, ownerUserId);
            return ServiceResult.NotFound(localizer["EventGuest.NotFound"], ErrorCodes.NotFound);
        }

        repo.Delete(guest);
        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("Guest {GuestId} removed from event {EventId}", guestId, eventId);
        return ServiceResult.Ok("Guest removed from event successfully.");
    }

    private async Task<ServiceResult<BulkAddGuestsResultDto>> AddGuestsAsync(string ownerUserId, int eventId, List<int> personIds)
    {
        var repo = unitOfWork.Repository<EventGuest, int>();
        var existingGuests = await repo.ListAllWithSpecAsync(EventGuestWithSpecs.ForEvent(eventId, ownerUserId));
        var existingPersonIds = existingGuests.Select(g => g.PersonId).ToHashSet();

        var newPersonIds = personIds.Where(id => !existingPersonIds.Contains(id)).ToList();

        if (newPersonIds.Count > 0)
        {
            var newGuests = newPersonIds.Select(personId => new EventGuest
            {
                EventId = eventId,
                PersonId = personId,
                Status = EventGuestStatus.NotInvited
            }).ToList();

            await repo.AddRangeAsync(newGuests);
            await unitOfWork.SaveChangesAsync();
        }

        logger.LogInformation("Added {AddedCount} of {RequestedCount} guests to event {EventId}", newPersonIds.Count, personIds.Count, eventId);

        return ServiceResult<BulkAddGuestsResultDto>.Ok(new BulkAddGuestsResultDto
        {
            RequestedCount = personIds.Count,
            AddedCount = newPersonIds.Count,
            AlreadyPresentCount = personIds.Count - newPersonIds.Count
        });
    }

    private async Task<bool> EventExistsAsync(int eventId, string ownerUserId)
    {
        var eventRepo = unitOfWork.Repository<Event, int>();
        return await eventRepo.GetByIdWithSpecAsync(new EventWithSpecs(eventId, ownerUserId)) is not null;
    }

    private static EventGuestDetailsDto BuildDetailsDto(EventGuest guest) => new()
    {
        Id = guest.Id,
        EventId = guest.EventId,
        PersonId = guest.PersonId,
        PersonName = guest.Person.Name,
        PersonPhoneNumber = guest.Person.PhoneNumber,
        GroupId = guest.Person.GroupId,
        GroupName = LocalizedTextResolver.Resolve(guest.Person.Group.Name, guest.Person.Group.NameAr),
        Status = guest.Status,
        InviteMethod = guest.InviteMethod,
        InvitedAt = guest.InvitedAt
    };

    private static EventGuestProfileDto BuildProfileDto(EventGuest guest) => new()
    {
        Id = guest.Id,
        PersonId = guest.PersonId,
        PersonName = guest.Person.Name,
        PersonPhoneNumber = guest.Person.PhoneNumber,
        GroupId = guest.Person.GroupId,
        GroupName = LocalizedTextResolver.Resolve(guest.Person.Group.Name, guest.Person.Group.NameAr),
        Status = guest.Status,
        InviteMethod = guest.InviteMethod,
        InvitedAt = guest.InvitedAt
    };
}
