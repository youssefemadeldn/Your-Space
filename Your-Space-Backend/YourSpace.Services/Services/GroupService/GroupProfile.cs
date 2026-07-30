using AutoMapper;
using YourSpace.Data.Entities;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.GroupService.Dtos;

namespace YourSpace.Services.Services.GroupService;

public class GroupProfile : Profile
{
    public GroupProfile()
    {
        CreateMap<Group, GroupDetailsDto>()
            .ForMember(d => d.Name, o => o.MapFrom(s => LocalizedTextResolver.Resolve(s.Name, s.NameAr)));

        CreateMap<Group, GroupProfileDto>()
            .ForMember(d => d.Name, o => o.MapFrom(s => LocalizedTextResolver.Resolve(s.Name, s.NameAr)));

        // Both maps above pick up NameAr automatically via AutoMapper's default
        // same-name/same-type member matching — no explicit .ForMember needed.
    }
}
