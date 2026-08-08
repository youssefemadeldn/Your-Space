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

public class SubGroupService_UpdateAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Data.Entities.SubGroup, int>> _subGroupRepo = new();

    public SubGroupService_UpdateAsyncTests()
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

        var result = await CreateSut().UpdateAsync("owner-1", 1, 99, new UpdateSubGroupDto { Name = "New Name" });

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("SubGroup.NotFound");
    }

    [Fact]
    public async Task Leaves_field_unchanged_when_omitted_from_request()
    {
        var subGroup = new Data.Entities.SubGroup { Id = 5, OwnerUserId = "owner-1", GroupId = 1, Name = "Immediate Family", NameAr = "العائلة المباشرة" };
        _subGroupRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Data.Entities.SubGroup>>())).ReturnsAsync(subGroup);

        // Only Name supplied — NameAr must survive untouched.
        var result = await CreateSut().UpdateAsync("owner-1", 1, 5, new UpdateSubGroupDto { Name = "Immediate Family (Updated)" });

        result.Success.Should().BeTrue();
        subGroup.Name.Should().Be("Immediate Family (Updated)");
        subGroup.NameAr.Should().Be("العائلة المباشرة");
        _subGroupRepo.Verify(r => r.Update(subGroup), Times.Once);
    }
}
