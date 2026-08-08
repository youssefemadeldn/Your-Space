using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using CityServiceImpl = YourSpace.Services.Services.CityService.CityService;

namespace YourSpace.WebAPI.Tests.Unit.Services.CityService;

public class CityService_GetDetailsAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<City, int>> _cityRepo = new();

    public CityService_GetDetailsAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<City, int>()).Returns(_cityRepo.Object);
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

        var result = await CreateSut().GetDetailsAsync("owner-1", 1, 42);

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(404);
        result.ErrorCode.Should().Be("City.NotFound");
    }

    [Fact]
    public async Task Returns_city_details_when_found()
    {
        var city = new City { Id = 5, OwnerUserId = "owner-1", GovernorateId = 1, Name = "Maadi" };
        _cityRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<City>>())).ReturnsAsync(city);

        var result = await CreateSut().GetDetailsAsync("owner-1", 1, 5);

        result.Success.Should().BeTrue();
        result.Data!.Id.Should().Be(5);
        result.Data.GovernorateId.Should().Be(1);
        result.Data.Name.Should().Be("Maadi");
    }
}
