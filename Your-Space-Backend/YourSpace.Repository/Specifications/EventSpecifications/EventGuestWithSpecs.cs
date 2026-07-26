using System.Linq.Expressions;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Specifications.Paginated;

namespace YourSpace.Repository.Specifications.EventSpecifications;

public class EventGuestWithSpecs : BaseSpecification<EventGuest>
{
    private EventGuestWithSpecs(Expression<Func<EventGuest, bool>> criteria)
        : base(criteria)
    {
    }

    // Duplicate-add check for one (event, person) pair
    public EventGuestWithSpecs(int eventId, string ownerUserId, int personId)
        : base(eg => eg.EventId == eventId && eg.Event.OwnerUserId == ownerUserId && eg.PersonId == personId)
    {
    }

    // Count for the grouped/filterable guest-list read (no Skip/Take — see PaginationSpecification's
    // count/list pairing note)
    public EventGuestWithSpecs(int eventId, string ownerUserId, int? groupId, EventGuestStatus? status)
        : base(BuildListPredicate(eventId, ownerUserId, groupId, status))
    {
    }

    // Paginated grouped/filterable guest-list read
    public EventGuestWithSpecs(int eventId, string ownerUserId, int? groupId, EventGuestStatus? status, PaginationSpecification paging)
        : base(BuildListPredicate(eventId, ownerUserId, groupId, status))
    {
        AddInclude(eg => eg.Person.Group);
        ApplyOrderBy(eg => eg.Person.Name);
        ApplyPaging(paging.PageSize * (paging.PageIndex - 1), paging.PageSize);
    }

    // Single guest row — scoped to both the specific parent Event (defense in depth against a
    // route eventId that doesn't actually match the guest row's real parent) and its owner.
    public static EventGuestWithSpecs ById(int guestId, int eventId, string ownerUserId)
    {
        var spec = new EventGuestWithSpecs(eg => eg.Id == guestId && eg.EventId == eventId && eg.Event.OwnerUserId == ownerUserId);
        spec.AddInclude(eg => eg.Person.Group);
        spec.AddInclude(eg => eg.Event);
        return spec;
    }

    // All guest rows for the event, unpaginated — feeds the per-group progress summary and the
    // reciprocity "already added" exclusion set.
    public static EventGuestWithSpecs ForEvent(int eventId, string ownerUserId)
    {
        var spec = new EventGuestWithSpecs(eg => eg.EventId == eventId && eg.Event.OwnerUserId == ownerUserId);
        spec.AddInclude(eg => eg.Person.Group);
        return spec;
    }

    private static Expression<Func<EventGuest, bool>> BuildListPredicate(int eventId, string ownerUserId, int? groupId, EventGuestStatus? status)
        => eg => eg.EventId == eventId
            && eg.Event.OwnerUserId == ownerUserId
            && (groupId == null || eg.Person.GroupId == groupId)
            && (status == null || eg.Status == status);
}
