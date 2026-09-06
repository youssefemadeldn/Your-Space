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

public class CityService_CreateAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Governorate, int>> _governorateRepo = new();
    private readonly Mock<IGenericRepository<City, int>> _cityRepo = new();

    public CityService_CreateAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Governorate, int>()).Returns(_governorateRepo.Object);
        _unitOfWork.Setup(u => u.Repository<City, int>()).Returns(_cityRepo.Object);
    }

    private CityServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<CityServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_parent_governorate_is_not_visible_to_owner()
    {
        _governorateRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Governorate>>())).ReturnsAsync((Governorate?)null);

        var result = await CreateSut().CreateAsync("owner-1", 99, new CreateCityDto { Name = "Maadi" });

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("City.GovernorateNotFound");
        _cityRepo.Verify(r => r.AddAsync(It.IsAny<City>()), Times.Never);
    }

    [Fact]
    public async Task Creates_city_under_a_locked_global_governorate()
    {
        // A locked/global governorate is still a valid parent for a user's own City — only the
        // Governorate row itself is locked, not what a user attaches underneath it.
        var governorate = new Governorate { Id = 1, OwnerUserId = null, Name = "Cairo", IsLocked = true };
        _governorateRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Governorate>>())).ReturnsAsync(governorate);

        var result = await CreateSut().CreateAsync("owner-1", 1, new CreateCityDto { Name = "Maadi" });

        result.Success.Should().BeTrue();
        result.StatusCode.Should().Be(201);
        result.Data!.Name.Should().Be("Maadi");
        _cityRepo.Verify(
            r => r.AddAsync(It.Is<City>(c => c.OwnerUserId == "owner-1" && c.GovernorateId == 1 && c.Name == "Maadi")),
            Times.Once);
    }
}
