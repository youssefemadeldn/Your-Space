using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Services.Services.GroupService.Dtos;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using GroupServiceImpl = YourSpace.Services.Services.GroupService.GroupService;

namespace YourSpace.WebAPI.Tests.Unit.Services.GroupService;

public class GroupService_CreateAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Group, int>> _groupRepo = new();

    public GroupService_CreateAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Group, int>()).Returns(_groupRepo.Object);
    }

    private GroupServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<GroupServiceImpl>>());

    [Fact]
    public async Task Creates_group_scoped_to_owner_and_returns_created_result()
    {
        var result = await CreateSut().CreateAsync("owner-1", new CreateGroupDto { Name = "Village Friends" });

        result.Success.Should().BeTrue();
        result.StatusCode.Should().Be(201);
        result.Data!.Name.Should().Be("Village Friends");
        _groupRepo.Verify(r => r.AddAsync(It.Is<Group>(g => g.OwnerUserId == "owner-1" && g.Name == "Village Friends")), Times.Once);
        _unitOfWork.Verify(u => u.SaveChangesAsync(), Times.Once);
    }
}
