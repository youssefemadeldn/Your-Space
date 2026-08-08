using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using CityServiceImpl = YourSpace.Services.Services.CityService.CityService;

namespace YourSpace.WebAPI.Tests.Unit.Services.CityService;

public class CityService_DeleteAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<City, int>> _cityRepo = new();
    private readonly Mock<IGenericRepository<Neighborhood, int>> _neighborhoodRepo = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();

    public CityService_DeleteAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<City, int>()).Returns(_cityRepo.Object);
        _unitOfWork.Setup(u => u.Repository<Neighborhood, int>()).Returns(_neighborhoodRepo.Object);
        _unitOfWork.Setup(u => u.Repository<Person, int>()).Returns(_personRepo.Object);
    }

    private CityServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<CityServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_city_does_not_exist_for_governorate_and_owner()
    {
        _cityRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<City>>())).ReturnsAsync((City?)null);

        var result = await CreateSut().DeleteAsync("owner-1", 1, 99);

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("City.NotFound");
    }

    [Fact]
    public async Task Returns_conflict_when_city_still_has_active_neighborhoods()
    {
        var city = new City { Id = 5, OwnerUserId = "owner-1", GovernorateId = 1, Name = "Maadi" };
        _cityRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<City>>())).ReturnsAsync(city);
        _neighborhoodRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Neighborhood>>())).ReturnsAsync(2);

        var result = await CreateSut().DeleteAsync("owner-1", 1, 5);

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(409);
        result.ErrorCode.Should().Be("City.HasActiveNeighborhoods");
        _personRepo.Verify(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Person>>()), Times.Never);
    }

    [Fact]
    public async Task Returns_conflict_when_city_still_has_active_persons()
    {
        var city = new City { Id = 5, OwnerUserId = "owner-1", GovernorateId = 1, Name = "Maadi" };
        _cityRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<City>>())).ReturnsAsync(city);
        _neighborhoodRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Neighborhood>>())).ReturnsAsync(0);
        _personRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync(1);

        var result = await CreateSut().DeleteAsync("owner-1", 1, 5);

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("City.HasActivePersons");
    }

    [Fact]
    public async Task Soft_deletes_city_when_no_active_children_remain()
    {
        var city = new City { Id = 5, OwnerUserId = "owner-1", GovernorateId = 1, Name = "Maadi" };
        _cityRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<City>>())).ReturnsAsync(city);
        _neighborhoodRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Neighborhood>>())).ReturnsAsync(0);
        _personRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync(0);

        var result = await CreateSut().DeleteAsync("owner-1", 1, 5);

        result.Success.Should().BeTrue();
        city.DeletedAt.Should().NotBeNull();
        _cityRepo.Verify(r => r.Update(city), Times.Once);
        _unitOfWork.Verify(u => u.SaveChangesAsync(), Times.Once);
    }
}
