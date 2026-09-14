using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Repository.Sync;
using YourSpace.Services.Services.GovernorateService.Dtos;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using GovernorateServiceImpl = YourSpace.Services.Services.GovernorateService.GovernorateService;

namespace YourSpace.WebAPI.Tests.Unit.Services.GovernorateService;

public class GovernorateService_UpdateAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Governorate, int>> _governorateRepo = new();
    private readonly Mock<ISyncVersionProvider> _syncVersionProvider = new();

    public GovernorateService_UpdateAsyncTests()
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
    public async Task Returns_not_found_when_governorate_is_not_visible_to_owner()
    {
        _governorateRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Governorate>>())).ReturnsAsync((Governorate?)null);

        var result = await CreateSut().UpdateAsync("owner-1", new UpdateGovernorateDto { Id = 99, Name = "New Name" });

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("Governorate.NotFound");
    }

    [Fact]
    public async Task Returns_conflict_when_governorate_is_locked()
    {
        var governorate = new Governorate { Id = 1, OwnerUserId = null, Name = "Cairo", IsLocked = true };
        _governorateRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Governorate>>())).ReturnsAsync(governorate);

        var result = await CreateSut().UpdateAsync("owner-1", new UpdateGovernorateDto { Id = 1, Name = "Renamed Cairo" });

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(409);
        result.ErrorCode.Should().Be("Governorate.Locked");
        governorate.Name.Should().Be("Cairo");
        _governorateRepo.Verify(r => r.Update(It.IsAny<Governorate>()), Times.Never);
    }

    [Fact]
    public async Task Returns_conflict_when_governorate_is_not_owned_by_caller()
    {
        // Defense-in-depth branch: GovernorateWithSpecs only ever resolves global-or-mine rows in
        // production, so this shouldn't be reachable there — but the guard clause itself is real
        // code, worth verifying in isolation from what the (mocked-away) spec would enforce.
        var governorate = new Governorate { Id = 1, OwnerUserId = "owner-2", Name = "Someone Else's", IsLocked = false };
        _governorateRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Governorate>>())).ReturnsAsync(governorate);

        var result = await CreateSut().UpdateAsync("owner-1", new UpdateGovernorateDto { Id = 1, Name = "Renamed" });

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("Governorate.NotOwned");
    }

    [Fact]
    public async Task Leaves_field_unchanged_when_omitted_from_request()
    {
        var governorate = new Governorate { Id = 5, OwnerUserId = "owner-1", Name = "My Governorate", NameAr = "محافظتي", IsLocked = false };
        _governorateRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Governorate>>())).ReturnsAsync(governorate);

        var result = await CreateSut().UpdateAsync("owner-1", new UpdateGovernorateDto { Id = 5, Name = "My Governorate (Updated)" });

        result.Success.Should().BeTrue();
        governorate.Name.Should().Be("My Governorate (Updated)");
        governorate.NameAr.Should().Be("محافظتي");
        _governorateRepo.Verify(r => r.Update(governorate), Times.Once);
    }

    [Fact]
    public async Task Assigns_a_new_syncversion_from_the_sequence_provider()
    {
        var governorate = new Governorate { Id = 5, OwnerUserId = "owner-1", Name = "My Governorate", IsLocked = false, SyncVersion = 1 };
        _governorateRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Governorate>>())).ReturnsAsync(governorate);
        _syncVersionProvider.Setup(s => s.NextValueAsync("Governorates_SyncVersion_seq", It.IsAny<CancellationToken>())).ReturnsAsync(42);

        var result = await CreateSut().UpdateAsync("owner-1", new UpdateGovernorateDto { Id = 5, Name = "My Governorate (Updated)" });

        result.Success.Should().BeTrue();
        governorate.SyncVersion.Should().Be(42);
    }
}
