using AutoMapper;
using YourSpace.Data.Entities;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.GovernorateService.Dtos;

namespace YourSpace.Services.Services.GovernorateService;

public class GovernorateProfile : Profile
{
    public GovernorateProfile()
    {
        CreateMap<Governorate, GovernorateDetailsDto>()
            .ForMember(d => d.Name, o => o.MapFrom(s => LocalizedTextResolver.Resolve(s.Name, s.NameAr)));

        // PersonCount is set explicitly by the service after mapping (batch query) — ignored here.
        CreateMap<Governorate, GovernorateProfileDto>()
            .ForMember(d => d.Name, o => o.MapFrom(s => LocalizedTextResolver.Resolve(s.Name, s.NameAr)))
            .ForMember(d => d.PersonCount, o => o.Ignore());
    }
}
