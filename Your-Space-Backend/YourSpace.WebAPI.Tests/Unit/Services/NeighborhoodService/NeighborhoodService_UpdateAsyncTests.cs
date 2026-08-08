using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Services.Services.NeighborhoodService.Dtos;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using NeighborhoodServiceImpl = YourSpace.Services.Services.NeighborhoodService.NeighborhoodService;

namespace YourSpace.WebAPI.Tests.Unit.Services.NeighborhoodService;

public class NeighborhoodService_UpdateAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Neighborhood, int>> _neighborhoodRepo = new();

    public NeighborhoodService_UpdateAsyncTests()
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

        var result = await CreateSut().UpdateAsync("owner-1", 1, 99, new UpdateNeighborhoodDto { Name = "New Name" });

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("Neighborhood.NotFound");
    }

    [Fact]
    public async Task Leaves_field_unchanged_when_omitted_from_request()
    {
        var neighborhood = new Neighborhood { Id = 5, OwnerUserId = "owner-1", CityId = 1, Name = "Sarayat", NameAr = "السرايات" };
        _neighborhoodRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Neighborhood>>())).ReturnsAsync(neighborhood);

        var result = await CreateSut().UpdateAsync("owner-1", 1, 5, new UpdateNeighborhoodDto { Name = "Sarayat (Updated)" });

        result.Success.Should().BeTrue();
        neighborhood.Name.Should().Be("Sarayat (Updated)");
        neighborhood.NameAr.Should().Be("السرايات");
        _neighborhoodRepo.Verify(r => r.Update(neighborhood), Times.Once);
    }
}
