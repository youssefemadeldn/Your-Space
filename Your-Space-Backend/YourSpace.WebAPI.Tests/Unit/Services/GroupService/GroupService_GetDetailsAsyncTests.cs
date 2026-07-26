using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using GroupServiceImpl = YourSpace.Services.Services.GroupService.GroupService;

namespace YourSpace.WebAPI.Tests.Unit.Services.GroupService;

public class GroupService_GetDetailsAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Group, int>> _groupRepo = new();

    public GroupService_GetDetailsAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Group, int>()).Returns(_groupRepo.Object);
    }

    private GroupServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<GroupServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_group_does_not_exist_for_owner()
    {
        _groupRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Group>>())).ReturnsAsync((Group?)null);

        var result = await CreateSut().GetDetailsAsync("owner-1", 42);

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(404);
        result.ErrorCode.Should().Be("Group.NotFound");
    }

    [Fact]
    public async Task Returns_group_details_when_found()
    {
        var group = new Group { Id = 5, OwnerUserId = "owner-1", Name = "Relatives", CreatedAt = DateTime.UtcNow };
        _groupRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Group>>())).ReturnsAsync(group);

        var result = await CreateSut().GetDetailsAsync("owner-1", 5);

        result.Success.Should().BeTrue();
        result.Data!.Id.Should().Be(5);
        result.Data.Name.Should().Be("Relatives");
    }
}
