using AutoMapper;
using YourSpace.Data.Entities;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.CityService.Dtos;

namespace YourSpace.Services.Services.CityService;

public class CityProfile : Profile
{
    public CityProfile()
    {
        CreateMap<City, CityDetailsDto>()
            .ForMember(d => d.Name, o => o.MapFrom(s => LocalizedTextResolver.Resolve(s.Name, s.NameAr)));

        // NeighborhoodCount/PersonCount are set explicitly by the service after mapping (batch
        // queries it doesn't have access to from inside an AutoMapper profile) — ignored here.
        CreateMap<City, CityProfileDto>()
            .ForMember(d => d.Name, o => o.MapFrom(s => LocalizedTextResolver.Resolve(s.Name, s.NameAr)))
            .ForMember(d => d.NeighborhoodCount, o => o.Ignore())
            .ForMember(d => d.PersonCount, o => o.Ignore());
    }
}
