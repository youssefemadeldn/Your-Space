using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using GovernorateServiceImpl = YourSpace.Services.Services.GovernorateService.GovernorateService;

namespace YourSpace.WebAPI.Tests.Unit.Services.GovernorateService;

public class GovernorateService_GetAllAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Governorate, int>> _governorateRepo = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();

    public GovernorateService_GetAllAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Governorate, int>()).Returns(_governorateRepo.Object);
        _unitOfWork.Setup(u => u.Repository<Person, int>()).Returns(_personRepo.Object);
    }

    private GovernorateServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<GovernorateServiceImpl>>());

    [Fact]
    public async Task Includes_both_global_and_owned_governorates_with_computed_person_counts()
    {
        var governorates = new List<Governorate>
        {
            new() { Id = 1, OwnerUserId = null, Name = "Cairo", IsLocked = true },
            new() { Id = 2, OwnerUserId = "owner-1", Name = "My Custom Governorate", IsLocked = false },
        };
        _governorateRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Governorate>>())).ReturnsAsync(2);
        _governorateRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Governorate>>())).ReturnsAsync(governorates);

        var people = new List<Person>
        {
            new() { Id = 1, OwnerUserId = "owner-1", Name = "A", Gender = Gender.Male, GroupId = 1, GovernorateId = 1 },
            new() { Id = 2, OwnerUserId = "owner-1", Name = "B", Gender = Gender.Female, GroupId = 1, GovernorateId = 1 },
        };
        _personRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync(people);

        var result = await CreateSut().GetAllAsync("owner-1", null, new PaginationSpecification { PageIndex = 1, PageSize = 50 });

        result.Success.Should().BeTrue();
        result.Data!.Items.Single(i => i.Id == 1).PersonCount.Should().Be(2);
        result.Data.Items.Single(i => i.Id == 2).PersonCount.Should().Be(0);
        result.Data.Items.Single(i => i.Id == 1).IsLocked.Should().BeTrue();
    }
}
