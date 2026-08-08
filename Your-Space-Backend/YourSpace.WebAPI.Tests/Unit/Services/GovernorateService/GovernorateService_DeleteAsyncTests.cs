using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using GovernorateServiceImpl = YourSpace.Services.Services.GovernorateService.GovernorateService;

namespace YourSpace.WebAPI.Tests.Unit.Services.GovernorateService;

public class GovernorateService_DeleteAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Governorate, int>> _governorateRepo = new();
    private readonly Mock<IGenericRepository<City, int>> _cityRepo = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();

    public GovernorateService_DeleteAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Governorate, int>()).Returns(_governorateRepo.Object);
        _unitOfWork.Setup(u => u.Repository<City, int>()).Returns(_cityRepo.Object);
        _unitOfWork.Setup(u => u.Repository<Person, int>()).Returns(_personRepo.Object);
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

        var result = await CreateSut().DeleteAsync("owner-1", 99);

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("Governorate.NotFound");
    }

    [Fact]
    public async Task Returns_conflict_when_governorate_is_locked()
    {
        var governorate = new Governorate { Id = 1, OwnerUserId = null, Name = "Cairo", IsLocked = true };
        _governorateRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Governorate>>())).ReturnsAsync(governorate);

        var result = await CreateSut().DeleteAsync("owner-1", 1);

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("Governorate.Locked");
        _governorateRepo.Verify(r => r.Update(It.IsAny<Governorate>()), Times.Never);
    }

    [Fact]
    public async Task Returns_conflict_when_governorate_still_has_active_cities()
    {
        var governorate = new Governorate { Id = 5, OwnerUserId = "owner-1", Name = "My Governorate", IsLocked = false };
        _governorateRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Governorate>>())).ReturnsAsync(governorate);
        _cityRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<City>>())).ReturnsAsync(2);

        var result = await CreateSut().DeleteAsync("owner-1", 5);

        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(409);
        result.ErrorCode.Should().Be("Governorate.HasActiveCities");
        _personRepo.Verify(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Person>>()), Times.Never);
    }

    [Fact]
    public async Task Returns_conflict_when_governorate_still_has_active_persons()
    {
        var governorate = new Governorate { Id = 5, OwnerUserId = "owner-1", Name = "My Governorate", IsLocked = false };
        _governorateRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Governorate>>())).ReturnsAsync(governorate);
        _cityRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<City>>())).ReturnsAsync(0);
        _personRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync(3);

        var result = await CreateSut().DeleteAsync("owner-1", 5);

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("Governorate.HasActivePersons");
        _governorateRepo.Verify(r => r.Update(It.IsAny<Governorate>()), Times.Never);
    }

    [Fact]
    public async Task Soft_deletes_governorate_when_unlocked_owned_and_childless()
    {
        var governorate = new Governorate { Id = 5, OwnerUserId = "owner-1", Name = "My Governorate", IsLocked = false };
        _governorateRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Governorate>>())).ReturnsAsync(governorate);
        _cityRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<City>>())).ReturnsAsync(0);
        _personRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync(0);

        var result = await CreateSut().DeleteAsync("owner-1", 5);

        result.Success.Should().BeTrue();
        governorate.DeletedAt.Should().NotBeNull();
        _governorateRepo.Verify(r => r.Update(governorate), Times.Once);
        _unitOfWork.Verify(u => u.SaveChangesAsync(), Times.Once);
    }
}
