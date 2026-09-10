using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using NeighborhoodServiceImpl = YourSpace.Services.Services.NeighborhoodService.NeighborhoodService;

namespace YourSpace.WebAPI.Tests.Unit.Services.NeighborhoodService;

public class NeighborhoodService_DeleteAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Neighborhood, int>> _neighborhoodRepo = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();

    public NeighborhoodService_DeleteAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Neighborhood, int>()).Returns(_neighborhoodRepo.Object);
        _unitOfWork.Setup(u => u.Repository<Person, int>()).Returns(_personRepo.Object);
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

        var result = await CreateSut().DeleteAsync("owner-1", 1, 99);

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("Neighborhood.NotFound");
    }

    [Fact]
    public async Task Returns_conflict_when_neighborhood_still_has_active_persons()
    {
        var neighborhood = new Neighborhood { Id = 5, OwnerUserId = "owner-1", CityId = 1, Name = "Sarayat" };
        _neighborhoodRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Neighborhood>>())).ReturnsAsync(neighborhood);
        _personRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync(4);

        var result = await CreateSut().DeleteAsync("owner-1", 1, 5);

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(409);
        result.ErrorCode.Should().Be("Neighborhood.HasActivePersons");
        _neighborhoodRepo.Verify(r => r.Update(It.IsAny<Neighborhood>()), Times.Never);
    }

    [Fact]
    public async Task Soft_deletes_neighborhood_when_no_active_persons_remain()
    {
        var neighborhood = new Neighborhood { Id = 5, OwnerUserId = "owner-1", CityId = 1, Name = "Sarayat" };
        _neighborhoodRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Neighborhood>>())).ReturnsAsync(neighborhood);
        _personRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync(0);

        var result = await CreateSut().DeleteAsync("owner-1", 1, 5);

        result.Success.Should().BeTrue();
        neighborhood.DeletedAt.Should().NotBeNull();
        _neighborhoodRepo.Verify(r => r.Update(neighborhood), Times.Once);
        _unitOfWork.Verify(u => u.SaveChangesAsync(), Times.Once);
    }
}
