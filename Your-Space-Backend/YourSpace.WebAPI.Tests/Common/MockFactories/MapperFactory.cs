using AutoMapper;
using Microsoft.Extensions.Logging.Abstractions;
using YourSpace.Services.Services.CityService;
using YourSpace.Services.Services.EventService;
using YourSpace.Services.Services.GovernorateService;
using YourSpace.Services.Services.GroupService;
using YourSpace.Services.Services.NeighborhoodService;
using YourSpace.Services.Services.PersonOccasionHistoryService;
using YourSpace.Services.Services.PersonService;
using YourSpace.Services.Services.SubGroupService;

namespace YourSpace.WebAPI.Tests.Common.MockFactories;

// A real AutoMapper instance built from the actual Profile classes — exercises the real
// Name/NameAr resolution logic instead of mocking Map<T>() with canned per-test output.
public static class MapperFactory
{
    public static IMapper Create()
    {
        var configuration = new MapperConfiguration(cfg =>
        {
            cfg.AddProfile<GroupProfile>();
            cfg.AddProfile<PersonProfile>();
            cfg.AddProfile<EventProfile>();
            cfg.AddProfile<PersonOccasionHistoryProfile>();
            cfg.AddProfile<SubGroupProfile>();
            cfg.AddProfile<GovernorateProfile>();
            cfg.AddProfile<CityProfile>();
            cfg.AddProfile<NeighborhoodProfile>();
        }, NullLoggerFactory.Instance);

        return configuration.CreateMapper();
    }
}
