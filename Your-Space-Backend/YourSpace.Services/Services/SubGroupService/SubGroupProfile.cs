using AutoMapper;
using YourSpace.Data.Entities;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.SubGroupService.Dtos;

namespace YourSpace.Services.Services.SubGroupService;

public class SubGroupProfile : Profile
{
    public SubGroupProfile()
    {
        CreateMap<SubGroup, SubGroupDetailsDto>()
            .ForMember(d => d.Name, o => o.MapFrom(s => LocalizedTextResolver.Resolve(s.Name, s.NameAr)));

        // PersonCount is set explicitly by the service after mapping (needs a batch Person query it
        // doesn't have access to from inside an AutoMapper profile) — ignored here, not omitted by
        // accident.
        CreateMap<SubGroup, SubGroupProfileDto>()
            .ForMember(d => d.Name, o => o.MapFrom(s => LocalizedTextResolver.Resolve(s.Name, s.NameAr)))
            .ForMember(d => d.PersonCount, o => o.Ignore());
    }
}
