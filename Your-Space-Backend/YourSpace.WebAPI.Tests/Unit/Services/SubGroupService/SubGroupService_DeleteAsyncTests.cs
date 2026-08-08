using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using SubGroupServiceImpl = YourSpace.Services.Services.SubGroupService.SubGroupService;

namespace YourSpace.WebAPI.Tests.Unit.Services.SubGroupService;

public class SubGroupService_DeleteAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Data.Entities.SubGroup, int>> _subGroupRepo = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();

    public SubGroupService_DeleteAsyncTests()
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
    public async Task Returns_not_found_when_subgroup_does_not_exist_for_group_and_owner()
    {
        _subGroupRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Data.Entities.SubGroup>>()))
            .ReturnsAsync((Data.Entities.SubGroup?)null);

        var result = await CreateSut().DeleteAsync("owner-1", 1, 99);

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("SubGroup.NotFound");
    }

    [Fact]
    public async Task Returns_conflict_when_subgroup_still_has_active_persons()
    {
        var subGroup = new Data.Entities.SubGroup { Id = 5, OwnerUserId = "owner-1", GroupId = 1, Name = "Immediate Family" };
        _subGroupRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Data.Entities.SubGroup>>())).ReturnsAsync(subGroup);
        _personRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync(2);

        var result = await CreateSut().DeleteAsync("owner-1", 1, 5);

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(409);
        result.ErrorCode.Should().Be("SubGroup.HasActivePersons");
        _subGroupRepo.Verify(r => r.Update(It.IsAny<Data.Entities.SubGroup>()), Times.Never);
    }

    [Fact]
    public async Task Soft_deletes_subgroup_when_no_active_persons_remain()
    {
        var subGroup = new Data.Entities.SubGroup { Id = 5, OwnerUserId = "owner-1", GroupId = 1, Name = "Immediate Family" };
        _subGroupRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Data.Entities.SubGroup>>())).ReturnsAsync(subGroup);
        _personRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync(0);

        var result = await CreateSut().DeleteAsync("owner-1", 1, 5);

        result.Success.Should().BeTrue();
        subGroup.DeletedAt.Should().NotBeNull();
        _subGroupRepo.Verify(r => r.Update(subGroup), Times.Once);
        _unitOfWork.Verify(u => u.SaveChangesAsync(), Times.Once);
    }
}
