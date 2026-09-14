using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Sync;
using YourSpace.Services.Services.GovernorateService.Dtos;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using GovernorateServiceImpl = YourSpace.Services.Services.GovernorateService.GovernorateService;

namespace YourSpace.WebAPI.Tests.Unit.Services.GovernorateService;

public class GovernorateService_CreateAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Governorate, int>> _governorateRepo = new();
    private readonly Mock<ISyncVersionProvider> _syncVersionProvider = new();

    public GovernorateService_CreateAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Governorate, int>()).Returns(_governorateRepo.Object);
        _syncVersionProvider.Setup(s => s.NextValueAsync(It.IsAny<string>(), It.IsAny<CancellationToken>())).ReturnsAsync(1);
    }

    private GovernorateServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        _syncVersionProvider.Object,
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

    [Fact]
    public async Task Assigns_a_syncversion_from_the_sequence_provider()
    {
        _syncVersionProvider.Setup(s => s.NextValueAsync("Governorates_SyncVersion_seq", It.IsAny<CancellationToken>())).ReturnsAsync(42);

        var result = await CreateSut().CreateAsync("owner-1", new CreateGovernorateDto { Name = "New Valley" });

        result.Success.Should().BeTrue();
        _governorateRepo.Verify(r => r.AddAsync(It.Is<Governorate>(g => g.SyncVersion == 42)), Times.Once);
    }
}
