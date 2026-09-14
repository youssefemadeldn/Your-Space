using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Repository.Sync;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using SubGroupServiceImpl = YourSpace.Services.Services.SubGroupService.SubGroupService;

namespace YourSpace.WebAPI.Tests.Unit.Services.SubGroupService;

public class SubGroupService_GetAllMineAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<SubGroup, int>> _subGroupRepo = new();

    public SubGroupService_GetAllMineAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<SubGroup, int>()).Returns(_subGroupRepo.Object);
    }

    private SubGroupServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ISyncVersionProvider>(),
        Mock.Of<ILogger<SubGroupServiceImpl>>());

    [Fact]
    public async Task Returns_subgroups_across_every_group_with_no_count_enrichment()
    {
        // The flat "all mine" pull feeds the mobile Tier 1 bulk sync (design doc §11 row 8.14),
        // which never reads PersonCount (design doc §8: server-computed values stay
        // network-only, never cached) — unlike GetAllAsync, this doesn't touch the Person repo
        // at all, so no mock setup for it is needed.
        var subGroups = new List<SubGroup>
        {
            new() { Id = 1, OwnerUserId = "owner-1", GroupId = 1, Name = "Immediate Family" },
            new() { Id = 2, OwnerUserId = "owner-1", GroupId = 2, Name = "University Friends" },
        };
        _subGroupRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<SubGroup>>())).ReturnsAsync(2);
        _subGroupRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<SubGroup>>())).ReturnsAsync(subGroups);

        var result = await CreateSut().GetAllMineAsync("owner-1", null, new PaginationSpecification { PageIndex = 1, PageSize = 200 });

        result.Success.Should().BeTrue();
        result.Data!.Items.Select(i => i.Id).Should().BeEquivalentTo([1, 2]);
        result.Data.Items.Select(i => i.GroupId).Should().BeEquivalentTo([1, 2]);
        result.Data.Items.Should().OnlyContain(i => i.PersonCount == 0);
    }

    [Fact]
    public async Task Reports_the_true_total_across_groups()
    {
        _subGroupRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<SubGroup>>())).ReturnsAsync(15);
        _subGroupRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<SubGroup>>())).ReturnsAsync(
            [new SubGroup { Id = 1, OwnerUserId = "owner-1", GroupId = 1, Name = "Immediate Family" }]);

        var result = await CreateSut().GetAllMineAsync("owner-1", null, new PaginationSpecification { PageIndex = 1, PageSize = 10 });

        result.Data!.TotalItems.Should().Be(15);
        result.Data.TotalPages.Should().Be(2);
    }
}
