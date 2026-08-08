using AutoMapper;
using YourSpace.Data.Entities;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.PersonService.Dtos;

namespace YourSpace.Services.Services.PersonService;

public class PersonProfile : Profile
{
    public PersonProfile()
    {
        // HasReciprocityHistory/OccasionHistory/Relationships/PrimaryPhotoUrl have no direct source
        // on Person itself — PersonService fetches/resolves them via separate queries and sets them
        // afterward (ignored here, not omitted by accident).
        CreateMap<Person, PersonDetailsDto>()
            .ForMember(d => d.GroupName, o => o.MapFrom(s => LocalizedTextResolver.Resolve(s.Group.Name, s.Group.NameAr)))
            .ForMember(d => d.SubGroupName, o => o.MapFrom(s => s.SubGroup == null ? null : LocalizedTextResolver.Resolve(s.SubGroup.Name, s.SubGroup.NameAr)))
            .ForMember(d => d.GovernorateName, o => o.MapFrom(s => LocalizedTextResolver.Resolve(s.Governorate.Name, s.Governorate.NameAr)))
            .ForMember(d => d.CityName, o => o.MapFrom(s => s.City == null ? null : LocalizedTextResolver.Resolve(s.City.Name, s.City.NameAr)))
            .ForMember(d => d.NeighborhoodName, o => o.MapFrom(s => s.Neighborhood == null ? null : LocalizedTextResolver.Resolve(s.Neighborhood.Name, s.Neighborhood.NameAr)))
            .ForMember(d => d.PrimaryPhotoUrl, o => o.Ignore())
            .ForMember(d => d.HasReciprocityHistory, o => o.Ignore())
            .ForMember(d => d.OccasionHistory, o => o.Ignore())
            .ForMember(d => d.Relationships, o => o.Ignore());

        CreateMap<Person, PersonProfileDto>()
            .ForMember(d => d.GroupName, o => o.MapFrom(s => LocalizedTextResolver.Resolve(s.Group.Name, s.Group.NameAr)))
            .ForMember(d => d.SubGroupName, o => o.MapFrom(s => s.SubGroup == null ? null : LocalizedTextResolver.Resolve(s.SubGroup.Name, s.SubGroup.NameAr)))
            .ForMember(d => d.GovernorateName, o => o.MapFrom(s => LocalizedTextResolver.Resolve(s.Governorate.Name, s.Governorate.NameAr)))
            .ForMember(d => d.CityName, o => o.MapFrom(s => s.City == null ? null : LocalizedTextResolver.Resolve(s.City.Name, s.City.NameAr)))
            .ForMember(d => d.NeighborhoodName, o => o.MapFrom(s => s.Neighborhood == null ? null : LocalizedTextResolver.Resolve(s.Neighborhood.Name, s.Neighborhood.NameAr)))
            .ForMember(d => d.PrimaryPhotoUrl, o => o.Ignore())
            .ForMember(d => d.HasReciprocityHistory, o => o.Ignore());
    }
}
