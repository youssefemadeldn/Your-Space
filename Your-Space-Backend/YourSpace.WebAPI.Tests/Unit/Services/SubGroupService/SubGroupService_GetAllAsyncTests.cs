using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using SubGroupServiceImpl = YourSpace.Services.Services.SubGroupService.SubGroupService;

namespace YourSpace.WebAPI.Tests.Unit.Services.SubGroupService;

public class SubGroupService_GetAllAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Data.Entities.SubGroup, int>> _subGroupRepo = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();

    public SubGroupService_GetAllAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Data.Entities.SubGroup, int>()).Returns(_subGroupRepo.Object);
        _unitOfWork.Setup(u => u.Repository<Person, int>()).Returns(_personRepo.Object);
    }

    private SubGroupServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<SubGroupServiceImpl>>());

    [Fact]
    public async Task Computes_total_pages_from_total_items_and_page_size()
    {
        _subGroupRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Data.Entities.SubGroup>>())).ReturnsAsync(25);
        _subGroupRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Data.Entities.SubGroup>>()))
            .ReturnsAsync([new Data.Entities.SubGroup { Id = 1, OwnerUserId = "owner-1", GroupId = 1, Name = "Immediate Family" }]);
        _personRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync([]);

        var result = await CreateSut().GetAllAsync("owner-1", 1, null, new PaginationSpecification { PageIndex = 1, PageSize = 10 });

        result.Success.Should().BeTrue();
        result.Data!.TotalItems.Should().Be(25);
        result.Data.TotalPages.Should().Be(3);
        result.Data.Items.Should().ContainSingle();
    }

    [Fact]
    public async Task Computes_person_count_per_subgroup_from_one_batch_query_not_per_row()
    {
        var subGroups = new List<Data.Entities.SubGroup>
        {
            new() { Id = 1, OwnerUserId = "owner-1", GroupId = 1, Name = "Immediate Family" },
            new() { Id = 2, OwnerUserId = "owner-1", GroupId = 1, Name = "Extended Family" },
        };
        _subGroupRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Data.Entities.SubGroup>>())).ReturnsAsync(2);
        _subGroupRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Data.Entities.SubGroup>>())).ReturnsAsync(subGroups);

        var people = new List<Person>
        {
            Person(1, subGroupId: 1),
            Person(2, subGroupId: 1),
            Person(3, subGroupId: 2),
            Person(4, subGroupId: null), // unassigned — must not count against either subgroup
        };
        _personRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync(people);

        var result = await CreateSut().GetAllAsync("owner-1", 1, null, new PaginationSpecification { PageIndex = 1, PageSize = 10 });

        result.Data!.Items.Single(i => i.Id == 1).PersonCount.Should().Be(2);
        result.Data.Items.Single(i => i.Id == 2).PersonCount.Should().Be(1);
        _personRepo.Verify(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Person>>()), Times.Once);
    }

    private static Person Person(int id, int? subGroupId) => new()
    {
        Id = id,
        OwnerUserId = "owner-1",
        Name = $"Person {id}",
        Gender = Gender.Male,
        GroupId = 1,
        SubGroupId = subGroupId,
        GovernorateId = 1
    };
}
