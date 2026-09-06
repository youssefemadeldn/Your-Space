using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Services.Services.CityService.Dtos;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using CityServiceImpl = YourSpace.Services.Services.CityService.CityService;

namespace YourSpace.WebAPI.Tests.Unit.Services.CityService;

public class CityService_UpdateAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<City, int>> _cityRepo = new();

    public CityService_UpdateAsyncTests()
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

        var result = await CreateSut().UpdateAsync("owner-1", 1, 99, new UpdateCityDto { Name = "New Name" });

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("City.NotFound");
    }

    [Fact]
    public async Task Leaves_field_unchanged_when_omitted_from_request()
    {
        var city = new City { Id = 5, OwnerUserId = "owner-1", GovernorateId = 1, Name = "Maadi", NameAr = "المعادي" };
        _cityRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<City>>())).ReturnsAsync(city);

        var result = await CreateSut().UpdateAsync("owner-1", 1, 5, new UpdateCityDto { Name = "Maadi (Updated)" });

        result.Success.Should().BeTrue();
        city.Name.Should().Be("Maadi (Updated)");
        city.NameAr.Should().Be("المعادي");
        _cityRepo.Verify(r => r.Update(city), Times.Once);
    }
}
