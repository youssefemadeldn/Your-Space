using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Services.Services.GovernorateService.Dtos;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using GovernorateServiceImpl = YourSpace.Services.Services.GovernorateService.GovernorateService;

namespace YourSpace.WebAPI.Tests.Unit.Services.GovernorateService;

public class GovernorateService_CreateAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Governorate, int>> _governorateRepo = new();

    public GovernorateService_CreateAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Governorate, int>()).Returns(_governorateRepo.Object);
    }

    private GovernorateServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<GovernorateServiceImpl>>());

    [Fact]
    public async Task Creates_governorate_owned_by_caller_and_never_locked()
    {
        var result = await CreateSut().CreateAsync("owner-1", new CreateGovernorateDto { Name = "New Valley" });

        result.Success.Should().BeTrue();
        result.StatusCode.Should().Be(201);
        result.Data!.Name.Should().Be("New Valley");
        result.Data.IsLocked.Should().BeFalse();
        _governorateRepo.Verify(
            r => r.AddAsync(It.Is<Governorate>(g => g.OwnerUserId == "owner-1" && !g.IsLocked && g.Name == "New Valley")),
            Times.Once);
        _unitOfWork.Verify(u => u.SaveChangesAsync(), Times.Once);
    }
}
