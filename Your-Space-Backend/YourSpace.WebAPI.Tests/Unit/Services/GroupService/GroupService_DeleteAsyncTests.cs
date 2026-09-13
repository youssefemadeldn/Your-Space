using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Repository.Sync;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using GroupServiceImpl = YourSpace.Services.Services.GroupService.GroupService;

namespace YourSpace.WebAPI.Tests.Unit.Services.GroupService;

public class GroupService_DeleteAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Group, int>> _groupRepo = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();
    private readonly Mock<ISyncVersionProvider> _syncVersionProvider = new();

    public GroupService_DeleteAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Group, int>()).Returns(_groupRepo.Object);
        _unitOfWork.Setup(u => u.Repository<Person, int>()).Returns(_personRepo.Object);
        _syncVersionProvider.Setup(s => s.NextValueAsync(It.IsAny<string>(), It.IsAny<CancellationToken>())).ReturnsAsync(1);
    }

    private GroupServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        _syncVersionProvider.Object,
        Mock.Of<ILogger<GroupServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_group_does_not_exist_for_owner()
    {
        _groupRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Group>>())).ReturnsAsync((Group?)null);

        var result = await CreateSut().DeleteAsync("owner-1", 99);

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("Group.NotFound");
    }

    [Fact]
    public async Task Returns_conflict_when_group_still_has_active_persons()
    {
        var group = new Group { Id = 5, OwnerUserId = "owner-1", Name = "Relatives" };
        _groupRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Group>>())).ReturnsAsync(group);
        _personRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync(3);

        var result = await CreateSut().DeleteAsync("owner-1", 5);

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(409);
        result.ErrorCode.Should().Be("Group.HasActivePersons");
        _groupRepo.Verify(r => r.Update(It.IsAny<Group>()), Times.Never);
        _unitOfWork.Verify(u => u.SaveChangesAsync(), Times.Never);
    }

    [Fact]
    public async Task Soft_deletes_group_when_no_active_persons_remain()
    {
        var group = new Group { Id = 5, OwnerUserId = "owner-1", Name = "Relatives" };
        _groupRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Group>>())).ReturnsAsync(group);
        _personRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync(0);

        var result = await CreateSut().DeleteAsync("owner-1", 5);

        result.Success.Should().BeTrue();
        group.DeletedAt.Should().NotBeNull();
        _groupRepo.Verify(r => r.Update(group), Times.Once);
        _unitOfWork.Verify(u => u.SaveChangesAsync(), Times.Once);
    }

    [Fact]
    public async Task Assigns_a_new_syncversion_on_soft_delete()
    {
        var group = new Group { Id = 5, OwnerUserId = "owner-1", Name = "Relatives", SyncVersion = 1 };
        _groupRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Group>>())).ReturnsAsync(group);
        _personRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync(0);
        _syncVersionProvider.Setup(s => s.NextValueAsync("Groups_SyncVersion_seq", It.IsAny<CancellationToken>())).ReturnsAsync(42);

        var result = await CreateSut().DeleteAsync("owner-1", 5);

        result.Success.Should().BeTrue();
        group.SyncVersion.Should().Be(42);
    }
}
