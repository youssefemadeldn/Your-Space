using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Services.Services.GroupService.Dtos;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using GroupServiceImpl = YourSpace.Services.Services.GroupService.GroupService;

namespace YourSpace.WebAPI.Tests.Unit.Services.GroupService;

public class GroupService_UpdateAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Group, int>> _groupRepo = new();

    public GroupService_UpdateAsyncTests()
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

        var result = await CreateSut().UpdateAsync("owner-1", new UpdateGroupDto { Id = 99, Name = "New Name" });

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("Group.NotFound");
    }

    [Fact]
    public async Task Leaves_field_unchanged_when_omitted_from_request()
    {
        var group = new Group { Id = 5, OwnerUserId = "owner-1", Name = "Relatives", NameAr = "الأقارب" };
        _groupRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Group>>())).ReturnsAsync(group);

        // Only Name supplied — NameAr must survive untouched.
        var result = await CreateSut().UpdateAsync("owner-1", new UpdateGroupDto { Id = 5, Name = "Relatives (Updated)" });

        result.Success.Should().BeTrue();
        group.Name.Should().Be("Relatives (Updated)");
        group.NameAr.Should().Be("الأقارب");
        _groupRepo.Verify(r => r.Update(group), Times.Once);
    }
}
