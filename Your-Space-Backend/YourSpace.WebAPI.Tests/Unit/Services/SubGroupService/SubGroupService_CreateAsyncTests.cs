using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Services.Services.SubGroupService.Dtos;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using SubGroupServiceImpl = YourSpace.Services.Services.SubGroupService.SubGroupService;

namespace YourSpace.WebAPI.Tests.Unit.Services.SubGroupService;

public class SubGroupService_CreateAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Group, int>> _groupRepo = new();
    private readonly Mock<IGenericRepository<Data.Entities.SubGroup, int>> _subGroupRepo = new();

    public SubGroupService_CreateAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Group, int>()).Returns(_groupRepo.Object);
        _unitOfWork.Setup(u => u.Repository<Data.Entities.SubGroup, int>()).Returns(_subGroupRepo.Object);
    }

    private SubGroupServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<SubGroupServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_parent_group_does_not_exist_for_owner()
    {
        _groupRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Group>>())).ReturnsAsync((Group?)null);

        var result = await CreateSut().CreateAsync("owner-1", 99, new CreateSubGroupDto { Name = "Immediate Family" });

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("SubGroup.GroupNotFound");
        _subGroupRepo.Verify(r => r.AddAsync(It.IsAny<Data.Entities.SubGroup>()), Times.Never);
    }

    [Fact]
    public async Task Creates_subgroup_scoped_to_group_and_owner_and_returns_created_result()
    {
        var group = new Group { Id = 1, OwnerUserId = "owner-1", Name = "Family" };
        _groupRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Group>>())).ReturnsAsync(group);

        var result = await CreateSut().CreateAsync("owner-1", 1, new CreateSubGroupDto { Name = "Immediate Family" });

        result.Success.Should().BeTrue();
        result.StatusCode.Should().Be(201);
        result.Data!.Name.Should().Be("Immediate Family");
        _subGroupRepo.Verify(
            r => r.AddAsync(It.Is<Data.Entities.SubGroup>(s => s.OwnerUserId == "owner-1" && s.GroupId == 1 && s.Name == "Immediate Family")),
            Times.Once);
        _unitOfWork.Verify(u => u.SaveChangesAsync(), Times.Once);
    }
}
