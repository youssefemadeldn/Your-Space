using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using CityServiceImpl = YourSpace.Services.Services.CityService.CityService;

namespace YourSpace.WebAPI.Tests.Unit.Services.CityService;

public class CityService_GetAllAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<City, int>> _cityRepo = new();
    private readonly Mock<IGenericRepository<Neighborhood, int>> _neighborhoodRepo = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();

    public CityService_GetAllAsyncTests()
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
    public async Task Computes_both_neighborhood_count_and_person_count_per_city()
    {
        var cities = new List<City>
        {
            new() { Id = 1, OwnerUserId = "owner-1", GovernorateId = 1, Name = "Maadi" },
            new() { Id = 2, OwnerUserId = "owner-1", GovernorateId = 1, Name = "Nasr City" },
        };
        _cityRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<City>>())).ReturnsAsync(2);
        _cityRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<City>>())).ReturnsAsync(cities);

        _neighborhoodRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Neighborhood>>())).ReturnsAsync(
        [
            new Neighborhood { Id = 1, OwnerUserId = "owner-1", CityId = 1, Name = "Sarayat" },
            new Neighborhood { Id = 2, OwnerUserId = "owner-1", CityId = 1, Name = "Zahraa" },
        ]);

        _personRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync(
        [
            new Person { Id = 1, OwnerUserId = "owner-1", Name = "A", Gender = Gender.Male, GroupId = 1, GovernorateId = 1, CityId = 1 },
            new Person { Id = 2, OwnerUserId = "owner-1", Name = "B", Gender = Gender.Female, GroupId = 1, GovernorateId = 1, CityId = 2 },
            new Person { Id = 3, OwnerUserId = "owner-1", Name = "C", Gender = Gender.Female, GroupId = 1, GovernorateId = 1, CityId = null },
        ]);

        var result = await CreateSut().GetAllAsync("owner-1", 1, null, new PaginationSpecification { PageIndex = 1, PageSize = 10 });

        var maadi = result.Data!.Items.Single(i => i.Id == 1);
        maadi.NeighborhoodCount.Should().Be(2);
        maadi.PersonCount.Should().Be(1);
        var nasrCity = result.Data.Items.Single(i => i.Id == 2);
        nasrCity.NeighborhoodCount.Should().Be(0);
        nasrCity.PersonCount.Should().Be(1);
    }
}
