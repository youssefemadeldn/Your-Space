using AutoMapper;
using YourSpace.Data.Entities;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.PersonService.Dtos;

namespace YourSpace.Services.Services.PersonService;

public class PersonProfile : Profile
{
    public PersonProfile()
    {
        // HasReciprocityHistory/OccasionHistory have no source on Person itself — PersonService
        // fetches them via a separate PersonOccasionHistory query and sets them afterward.
        CreateMap<Person, PersonDetailsDto>()
            .ForMember(d => d.GroupName, o => o.MapFrom(s => LocalizedTextResolver.Resolve(s.Group.Name, s.Group.NameAr)))
            .ForMember(d => d.HasReciprocityHistory, o => o.Ignore())
            .ForMember(d => d.OccasionHistory, o => o.Ignore());

        CreateMap<Person, PersonProfileDto>()
            .ForMember(d => d.GroupName, o => o.MapFrom(s => LocalizedTextResolver.Resolve(s.Group.Name, s.Group.NameAr)))
            .ForMember(d => d.HasReciprocityHistory, o => o.Ignore());
    }
}
