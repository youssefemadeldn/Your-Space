using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Repository.Sync;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using CityServiceImpl = YourSpace.Services.Services.CityService.CityService;

namespace YourSpace.WebAPI.Tests.Unit.Services.CityService;

public class CityService_GetAllMineAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<City, int>> _cityRepo = new();

    public CityService_GetAllMineAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<City, int>()).Returns(_cityRepo.Object);
    }

    private CityServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ISyncVersionProvider>(),
        Mock.Of<ILogger<CityServiceImpl>>());

    [Fact]
    public async Task Returns_cities_across_every_governorate_with_no_count_enrichment()
    {
        // The flat "all mine" pull feeds the mobile Tier 1 bulk sync (design doc §11 row 8.8),
        // which never reads NeighborhoodCount/PersonCount (design doc §8: server-computed values
        // stay network-only, never cached) — unlike GetAllAsync, this doesn't touch
        // Neighborhood/Person repos at all, so no mock setup for either is needed.
        var cities = new List<City>
        {
            new() { Id = 1, OwnerUserId = "owner-1", GovernorateId = 1, Name = "Maadi" },
            new() { Id = 2, OwnerUserId = "owner-1", GovernorateId = 2, Name = "6th of October" },
        };
        _cityRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<City>>())).ReturnsAsync(2);
        _cityRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<City>>())).ReturnsAsync(cities);

        var result = await CreateSut().GetAllMineAsync("owner-1", null, new PaginationSpecification { PageIndex = 1, PageSize = 200 });

        result.Success.Should().BeTrue();
        result.Data!.Items.Select(i => i.Id).Should().BeEquivalentTo([1, 2]);
        result.Data.Items.Select(i => i.GovernorateId).Should().BeEquivalentTo([1, 2]);
        result.Data.Items.Should().OnlyContain(i => i.NeighborhoodCount == 0 && i.PersonCount == 0);
    }

    [Fact]
    public async Task Reports_the_true_total_across_governorates()
    {
        _cityRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<City>>())).ReturnsAsync(15);
        _cityRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<City>>())).ReturnsAsync(
            [new City { Id = 1, OwnerUserId = "owner-1", GovernorateId = 1, Name = "Maadi" }]);

        var result = await CreateSut().GetAllMineAsync("owner-1", null, new PaginationSpecification { PageIndex = 1, PageSize = 10 });

        result.Data!.TotalItems.Should().Be(15);
        result.Data.TotalPages.Should().Be(2);
    }
}
