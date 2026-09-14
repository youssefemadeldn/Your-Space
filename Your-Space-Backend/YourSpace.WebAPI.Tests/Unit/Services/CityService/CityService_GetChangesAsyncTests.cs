using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Repository.Sync;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using CityServiceImpl = YourSpace.Services.Services.CityService.CityService;

namespace YourSpace.WebAPI.Tests.Unit.Services.CityService;

public class CityService_GetChangesAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<City, int>> _cityRepo = new();

    public CityService_GetChangesAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<City, int>()).Returns(_cityRepo.Object);
    }

    private CityServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ISyncVersionProvider>(),
        Mock.Of<ILogger<CityServiceImpl>>());

    private static City Alive(int id, long syncVersion) => new()
    {
        Id = id,
        OwnerUserId = "owner-1",
        GovernorateId = 7,
        Name = $"City {id}",
        SyncVersion = syncVersion
    };

    private static City Deleted(int id, long syncVersion) => new()
    {
        Id = id,
        OwnerUserId = "owner-1",
        GovernorateId = 7,
        Name = $"City {id}",
        SyncVersion = syncVersion,
        DeletedAt = DateTime.UtcNow
    };

    [Fact]
    public async Task Returns_empty_page_with_cursor_unchanged_when_nothing_has_changed()
    {
        _cityRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<City>>())).ReturnsAsync([]);

        var result = await CreateSut().GetChangesAsync("owner-1", since: 10, pageSize: 50);

        result.Success.Should().BeTrue();
        result.Data!.Upserts.Should().BeEmpty();
        result.Data.TombstoneIds.Should().BeEmpty();
        result.Data.Cursor.Should().Be(10);
        result.Data.HasMore.Should().BeFalse();
    }

    [Fact]
    public async Task Returns_upserts_only_when_every_changed_row_is_still_alive()
    {
        _cityRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<City>>()))
            .ReturnsAsync([Alive(1, 5), Alive(2, 7)]);

        var result = await CreateSut().GetChangesAsync("owner-1", since: 0, pageSize: 50);

        result.Data!.Upserts.Select(c => c.Id).Should().BeEquivalentTo([1, 2]);
        result.Data.TombstoneIds.Should().BeEmpty();
        result.Data.Cursor.Should().Be(7);
    }

    [Fact]
    public async Task Returns_tombstones_only_when_every_changed_row_is_soft_deleted()
    {
        _cityRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<City>>()))
            .ReturnsAsync([Deleted(3, 9)]);

        var result = await CreateSut().GetChangesAsync("owner-1", since: 0, pageSize: 50);

        result.Data!.Upserts.Should().BeEmpty();
        result.Data.TombstoneIds.Should().BeEquivalentTo([3]);
        result.Data.Cursor.Should().Be(9);
    }

    [Fact]
    public async Task Splits_a_mixed_page_into_upserts_and_tombstones_and_takes_the_max_syncversion_as_cursor()
    {
        _cityRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<City>>()))
            .ReturnsAsync([Alive(1, 5), Deleted(2, 11), Alive(3, 8)]);

        var result = await CreateSut().GetChangesAsync("owner-1", since: 0, pageSize: 50);

        result.Data!.Upserts.Select(c => c.Id).Should().BeEquivalentTo([1, 3]);
        result.Data.TombstoneIds.Should().BeEquivalentTo([2]);
        result.Data.Cursor.Should().Be(11);
    }

    [Fact]
    public async Task HasMore_is_true_when_the_page_returned_is_exactly_full()
    {
        _cityRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<City>>()))
            .ReturnsAsync([Alive(1, 1), Alive(2, 2)]);

        var result = await CreateSut().GetChangesAsync("owner-1", since: 0, pageSize: 2);

        result.Data!.HasMore.Should().BeTrue();
    }

    [Fact]
    public async Task HasMore_is_false_when_the_page_returned_is_under_the_requested_size()
    {
        _cityRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<City>>()))
            .ReturnsAsync([Alive(1, 1)]);

        var result = await CreateSut().GetChangesAsync("owner-1", since: 0, pageSize: 2);

        result.Data!.HasMore.Should().BeFalse();
    }

    [Fact]
    public async Task Rejects_a_negative_since_cursor()
    {
        var result = await CreateSut().GetChangesAsync("owner-1", since: -1, pageSize: 50);

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("City.Since.Invalid");
        _cityRepo.Verify(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<City>>()), Times.Never);
    }
}
