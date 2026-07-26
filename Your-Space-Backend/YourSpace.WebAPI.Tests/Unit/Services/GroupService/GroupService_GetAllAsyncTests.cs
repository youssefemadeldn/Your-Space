using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using GroupServiceImpl = YourSpace.Services.Services.GroupService.GroupService;

namespace YourSpace.WebAPI.Tests.Unit.Services.GroupService;

public class GroupService_GetAllAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Group, int>> _groupRepo = new();

    public GroupService_GetAllAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Group, int>()).Returns(_groupRepo.Object);
    }

    private GroupServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<GroupServiceImpl>>());

    [Fact]
    public async Task Computes_total_pages_from_total_items_and_page_size()
    {
        _groupRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Group>>())).ReturnsAsync(25);
        _groupRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Group>>()))
            .ReturnsAsync([new Group { Id = 1, OwnerUserId = "owner-1", Name = "Relatives" }]);

        var result = await CreateSut().GetAllAsync("owner-1", null, new PaginationSpecification { PageIndex = 1, PageSize = 10 });

        result.Success.Should().BeTrue();
        result.Data!.TotalItems.Should().Be(25);
        result.Data.TotalPages.Should().Be(3);
        result.Data.Items.Should().ContainSingle();
    }
}
