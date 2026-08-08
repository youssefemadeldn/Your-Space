using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using NeighborhoodServiceImpl = YourSpace.Services.Services.NeighborhoodService.NeighborhoodService;

namespace YourSpace.WebAPI.Tests.Unit.Services.NeighborhoodService;

public class NeighborhoodService_GetAllAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Neighborhood, int>> _neighborhoodRepo = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();

    public NeighborhoodService_GetAllAsyncTests()
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
    public async Task Computes_person_count_per_neighborhood_from_one_batch_query()
    {
        var neighborhoods = new List<Neighborhood>
        {
            new() { Id = 1, OwnerUserId = "owner-1", CityId = 1, Name = "Sarayat" },
            new() { Id = 2, OwnerUserId = "owner-1", CityId = 1, Name = "Zahraa" },
        };
        _neighborhoodRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Neighborhood>>())).ReturnsAsync(2);
        _neighborhoodRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Neighborhood>>())).ReturnsAsync(neighborhoods);

        _personRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync(
        [
            new Person { Id = 1, OwnerUserId = "owner-1", Name = "A", Gender = Gender.Male, GroupId = 1, GovernorateId = 1, NeighborhoodId = 1 },
            new Person { Id = 2, OwnerUserId = "owner-1", Name = "B", Gender = Gender.Female, GroupId = 1, GovernorateId = 1, NeighborhoodId = null },
        ]);

        var result = await CreateSut().GetAllAsync("owner-1", 1, null, new PaginationSpecification { PageIndex = 1, PageSize = 10 });

        result.Data!.Items.Single(i => i.Id == 1).PersonCount.Should().Be(1);
        result.Data.Items.Single(i => i.Id == 2).PersonCount.Should().Be(0);
    }
}
