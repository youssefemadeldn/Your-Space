using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using SubGroupServiceImpl = YourSpace.Services.Services.SubGroupService.SubGroupService;

namespace YourSpace.WebAPI.Tests.Unit.Services.SubGroupService;

public class SubGroupService_GetDetailsAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Data.Entities.SubGroup, int>> _subGroupRepo = new();

    public SubGroupService_GetDetailsAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Data.Entities.SubGroup, int>()).Returns(_subGroupRepo.Object);
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

        var result = await CreateSut().GetDetailsAsync("owner-1", 1, 42);

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(404);
        result.ErrorCode.Should().Be("SubGroup.NotFound");
    }

    [Fact]
    public async Task Returns_subgroup_details_when_found()
    {
        var subGroup = new Data.Entities.SubGroup { Id = 5, OwnerUserId = "owner-1", GroupId = 1, Name = "Immediate Family" };
        _subGroupRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Data.Entities.SubGroup>>())).ReturnsAsync(subGroup);

        var result = await CreateSut().GetDetailsAsync("owner-1", 1, 5);

        result.Success.Should().BeTrue();
        result.Data!.Id.Should().Be(5);
        result.Data.GroupId.Should().Be(1);
        result.Data.Name.Should().Be("Immediate Family");
    }
}
