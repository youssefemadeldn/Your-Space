using AutoMapper;
using YourSpace.Data.Entities;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.NeighborhoodService.Dtos;

namespace YourSpace.Services.Services.NeighborhoodService;

public class NeighborhoodProfile : Profile
{
    public NeighborhoodProfile()
    {
        CreateMap<Neighborhood, NeighborhoodDetailsDto>()
            .ForMember(d => d.Name, o => o.MapFrom(s => LocalizedTextResolver.Resolve(s.Name, s.NameAr)));

        // PersonCount is set explicitly by the service after mapping (batch query) — ignored here.
        CreateMap<Neighborhood, NeighborhoodProfileDto>()
            .ForMember(d => d.Name, o => o.MapFrom(s => LocalizedTextResolver.Resolve(s.Name, s.NameAr)))
            .ForMember(d => d.PersonCount, o => o.Ignore());
    }
}
