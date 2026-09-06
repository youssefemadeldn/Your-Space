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

public class NeighborhoodService_CreateAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<City, int>> _cityRepo = new();
    private readonly Mock<IGenericRepository<Neighborhood, int>> _neighborhoodRepo = new();

    public NeighborhoodService_CreateAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<City, int>()).Returns(_cityRepo.Object);
        _unitOfWork.Setup(u => u.Repository<Neighborhood, int>()).Returns(_neighborhoodRepo.Object);
    }

    private NeighborhoodServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<NeighborhoodServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_parent_city_does_not_exist_for_owner()
    {
        _cityRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<City>>())).ReturnsAsync((City?)null);

        var result = await CreateSut().CreateAsync("owner-1", 99, new CreateNeighborhoodDto { Name = "Sarayat" });

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("Neighborhood.CityNotFound");
        _neighborhoodRepo.Verify(r => r.AddAsync(It.IsAny<Neighborhood>()), Times.Never);
    }

    [Fact]
    public async Task Creates_neighborhood_scoped_to_city_and_owner()
    {
        var city = new City { Id = 1, OwnerUserId = "owner-1", GovernorateId = 1, Name = "Maadi" };
        _cityRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<City>>())).ReturnsAsync(city);

        var result = await CreateSut().CreateAsync("owner-1", 1, new CreateNeighborhoodDto { Name = "Sarayat" });

        result.Success.Should().BeTrue();
        result.StatusCode.Should().Be(201);
        result.Data!.Name.Should().Be("Sarayat");
        _neighborhoodRepo.Verify(
            r => r.AddAsync(It.Is<Neighborhood>(n => n.OwnerUserId == "owner-1" && n.CityId == 1 && n.Name == "Sarayat")),
            Times.Once);
    }
}
