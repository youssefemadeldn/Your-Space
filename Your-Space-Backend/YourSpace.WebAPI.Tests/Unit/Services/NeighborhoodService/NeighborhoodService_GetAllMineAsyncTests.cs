using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using NeighborhoodServiceImpl = YourSpace.Services.Services.NeighborhoodService.NeighborhoodService;

namespace YourSpace.WebAPI.Tests.Unit.Services.NeighborhoodService;

public class NeighborhoodService_GetAllMineAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Neighborhood, int>> _neighborhoodRepo = new();

    public NeighborhoodService_GetAllMineAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Neighborhood, int>()).Returns(_neighborhoodRepo.Object);
    }

    private NeighborhoodServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<NeighborhoodServiceImpl>>());

    [Fact]
    public async Task Returns_neighborhoods_across_every_city_with_no_count_enrichment()
    {
        // The flat "all mine" pull feeds the mobile Tier 1 bulk sync (design doc §11 row 8.20),
        // which never reads PersonCount (design doc §8: server-computed values stay
        // network-only, never cached) — unlike GetAllAsync, this doesn't touch the Person repo
        // at all, so no mock setup for it is needed.
        var neighborhoods = new List<Neighborhood>
        {
            new() { Id = 1, OwnerUserId = "owner-1", CityId = 1, Name = "Zamalek" },
            new() { Id = 2, OwnerUserId = "owner-1", CityId = 2, Name = "Sarayat" },
        };
        _neighborhoodRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Neighborhood>>())).ReturnsAsync(2);
        _neighborhoodRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Neighborhood>>())).ReturnsAsync(neighborhoods);

        var result = await CreateSut().GetAllMineAsync("owner-1", null, new PaginationSpecification { PageIndex = 1, PageSize = 200 });

        result.Success.Should().BeTrue();
        result.Data!.Items.Select(i => i.Id).Should().BeEquivalentTo([1, 2]);
        result.Data.Items.Select(i => i.CityId).Should().BeEquivalentTo([1, 2]);
        result.Data.Items.Should().OnlyContain(i => i.PersonCount == 0);
    }

    [Fact]
    public async Task Reports_the_true_total_across_cities()
    {
        _neighborhoodRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Neighborhood>>())).ReturnsAsync(15);
        _neighborhoodRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Neighborhood>>())).ReturnsAsync(
            [new Neighborhood { Id = 1, OwnerUserId = "owner-1", CityId = 1, Name = "Zamalek" }]);

        var result = await CreateSut().GetAllMineAsync("owner-1", null, new PaginationSpecification { PageIndex = 1, PageSize = 10 });

        result.Data!.TotalItems.Should().Be(15);
        result.Data.TotalPages.Should().Be(2);
    }
}
