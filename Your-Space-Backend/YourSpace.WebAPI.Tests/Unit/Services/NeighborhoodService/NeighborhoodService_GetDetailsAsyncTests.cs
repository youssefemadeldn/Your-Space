using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using NeighborhoodServiceImpl = YourSpace.Services.Services.NeighborhoodService.NeighborhoodService;

namespace YourSpace.WebAPI.Tests.Unit.Services.NeighborhoodService;

public class NeighborhoodService_GetDetailsAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Neighborhood, int>> _neighborhoodRepo = new();

    public NeighborhoodService_GetDetailsAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Neighborhood, int>()).Returns(_neighborhoodRepo.Object);
    }

    private NeighborhoodServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<NeighborhoodServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_neighborhood_does_not_exist_for_city_and_owner()
    {
        _neighborhoodRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Neighborhood>>())).ReturnsAsync((Neighborhood?)null);

        var result = await CreateSut().GetDetailsAsync("owner-1", 1, 42);

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(404);
        result.ErrorCode.Should().Be("Neighborhood.NotFound");
    }

    [Fact]
    public async Task Returns_neighborhood_details_when_found()
    {
        var neighborhood = new Neighborhood { Id = 5, OwnerUserId = "owner-1", CityId = 1, Name = "Sarayat" };
        _neighborhoodRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Neighborhood>>())).ReturnsAsync(neighborhood);

        var result = await CreateSut().GetDetailsAsync("owner-1", 1, 5);

        result.Success.Should().BeTrue();
        result.Data!.Id.Should().Be(5);
        result.Data.CityId.Should().Be(1);
        result.Data.Name.Should().Be("Sarayat");
    }
}
