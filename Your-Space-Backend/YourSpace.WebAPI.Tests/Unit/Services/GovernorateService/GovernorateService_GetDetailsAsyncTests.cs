using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using GovernorateServiceImpl = YourSpace.Services.Services.GovernorateService.GovernorateService;

namespace YourSpace.WebAPI.Tests.Unit.Services.GovernorateService;

public class GovernorateService_GetDetailsAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Governorate, int>> _governorateRepo = new();

    public GovernorateService_GetDetailsAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Governorate, int>()).Returns(_governorateRepo.Object);
    }

    private GovernorateServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<GovernorateServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_governorate_is_not_visible_to_owner()
    {
        _governorateRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Governorate>>())).ReturnsAsync((Governorate?)null);

        var result = await CreateSut().GetDetailsAsync("owner-1", 42);

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(404);
        result.ErrorCode.Should().Be("Governorate.NotFound");
    }

    [Fact]
    public async Task Returns_global_seeded_governorate_details()
    {
        var governorate = new Governorate { Id = 1, OwnerUserId = null, Name = "Cairo", IsLocked = true };
        _governorateRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Governorate>>())).ReturnsAsync(governorate);

        var result = await CreateSut().GetDetailsAsync("owner-1", 1);

        result.Success.Should().BeTrue();
        result.Data!.Name.Should().Be("Cairo");
        result.Data.IsLocked.Should().BeTrue();
    }
}
