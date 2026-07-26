using AutoMapper;
using YourSpace.Data.Entities;
using YourSpace.Services.Services.PersonOccasionHistoryService.Dtos;

namespace YourSpace.Services.Services.PersonOccasionHistoryService;

public class PersonOccasionHistoryProfile : Profile
{
    public PersonOccasionHistoryProfile()
    {
        // No bilingual/computed fields here — every destination member matches an entity property
        // by name and type, so the default convention-based mapping is enough.
        CreateMap<PersonOccasionHistory, PersonOccasionHistoryDetailsDto>();
        CreateMap<PersonOccasionHistory, PersonOccasionHistoryProfileDto>();
    }
}
