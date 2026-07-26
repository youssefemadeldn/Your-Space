using AutoMapper;
using YourSpace.Data.Entities;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.EventService.Dtos;

namespace YourSpace.Services.Services.EventService;

public class EventProfile : Profile
{
    public EventProfile()
    {
        // Guest counts have no source on Event itself — EventService fetches them via a separate
        // EventGuest query and sets them on the mapped instance afterward.
        CreateMap<Event, EventDetailsDto>()
            .ForMember(d => d.Name, o => o.MapFrom(s => LocalizedTextResolver.Resolve(s.Name, s.NameAr)))
            .ForMember(d => d.TotalGuestCount, o => o.Ignore())
            .ForMember(d => d.NotInvitedCount, o => o.Ignore())
            .ForMember(d => d.InvitedCount, o => o.Ignore())
            .ForMember(d => d.SkippedCount, o => o.Ignore());

        CreateMap<Event, EventProfileDto>()
            .ForMember(d => d.Name, o => o.MapFrom(s => LocalizedTextResolver.Resolve(s.Name, s.NameAr)))
            .ForMember(d => d.TotalGuestCount, o => o.Ignore());
    }
}
