using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Repository.Sync;
using YourSpace.Services.Services.StorageService;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using PersonServiceImpl = YourSpace.Services.Services.PersonService.PersonService;

namespace YourSpace.WebAPI.Tests.Unit.Services.PersonService;

public class PersonService_GetChangesAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();
    private readonly Mock<IGenericRepository<PersonOccasionHistory, int>> _historyRepo = new();
    private readonly Mock<IGenericRepository<PersonImage, int>> _imageRepo = new();

    public PersonService_GetChangesAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<Person, int>()).Returns(_personRepo.Object);
        _unitOfWork.Setup(u => u.Repository<PersonOccasionHistory, int>()).Returns(_historyRepo.Object);
        _unitOfWork.Setup(u => u.Repository<PersonImage, int>()).Returns(_imageRepo.Object);
        _historyRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<PersonOccasionHistory>>())).ReturnsAsync([]);
        _imageRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<PersonImage>>())).ReturnsAsync([]);
    }

    private PersonServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        Mock.Of<IR2StorageService>(),
        R2SettingsFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ISyncVersionProvider>(),
        Mock.Of<ILogger<PersonServiceImpl>>());

    private static Person Alive(int id, long syncVersion) => new()
    {
        Id = id,
        OwnerUserId = "owner-1",
        Name = $"Person {id}",
        Gender = Gender.Male,
        GroupId = 1,
        GovernorateId = 1,
        Group = new Group { Id = 1, OwnerUserId = "owner-1", Name = "Relatives" },
        Governorate = new Governorate { Id = 1, OwnerUserId = null, IsLocked = true, Name = "Cairo" },
        SyncVersion = syncVersion
    };

    private static Person Deleted(int id, long syncVersion) => new()
    {
        Id = id,
        OwnerUserId = "owner-1",
        Name = $"Person {id}",
        Gender = Gender.Male,
        GroupId = 1,
        GovernorateId = 1,
        Group = new Group { Id = 1, OwnerUserId = "owner-1", Name = "Relatives" },
        Governorate = new Governorate { Id = 1, OwnerUserId = null, IsLocked = true, Name = "Cairo" },
        SyncVersion = syncVersion,
        DeletedAt = DateTime.UtcNow
    };

    [Fact]
    public async Task Returns_empty_page_with_cursor_unchanged_when_nothing_has_changed()
    {
        _personRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync([]);

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
        _personRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Person>>()))
            .ReturnsAsync([Alive(1, 5), Alive(2, 7)]);

        var result = await CreateSut().GetChangesAsync("owner-1", since: 0, pageSize: 50);

        result.Data!.Upserts.Select(p => p.Id).Should().BeEquivalentTo([1, 2]);
        result.Data.TombstoneIds.Should().BeEmpty();
        result.Data.Cursor.Should().Be(7);
    }

    [Fact]
    public async Task Returns_tombstones_only_when_every_changed_row_is_soft_deleted()
    {
        _personRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Person>>()))
            .ReturnsAsync([Deleted(3, 9)]);

        var result = await CreateSut().GetChangesAsync("owner-1", since: 0, pageSize: 50);

        result.Data!.Upserts.Should().BeEmpty();
        result.Data.TombstoneIds.Should().BeEquivalentTo([3]);
        result.Data.Cursor.Should().Be(9);
    }

    [Fact]
    public async Task Splits_a_mixed_page_into_upserts_and_tombstones_and_takes_the_max_syncversion_as_cursor()
    {
        _personRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Person>>()))
            .ReturnsAsync([Alive(1, 5), Deleted(2, 11), Alive(3, 8)]);

        var result = await CreateSut().GetChangesAsync("owner-1", since: 0, pageSize: 50);

        result.Data!.Upserts.Select(p => p.Id).Should().BeEquivalentTo([1, 3]);
        result.Data.TombstoneIds.Should().BeEquivalentTo([2]);
        result.Data.Cursor.Should().Be(11);
    }

    [Fact]
    public async Task HasMore_is_true_when_the_page_returned_is_exactly_full()
    {
        _personRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Person>>()))
            .ReturnsAsync([Alive(1, 1), Alive(2, 2)]);

        var result = await CreateSut().GetChangesAsync("owner-1", since: 0, pageSize: 2);

        result.Data!.HasMore.Should().BeTrue();
    }

    [Fact]
    public async Task HasMore_is_false_when_the_page_returned_is_under_the_requested_size()
    {
        _personRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Person>>()))
            .ReturnsAsync([Alive(1, 1)]);

        var result = await CreateSut().GetChangesAsync("owner-1", since: 0, pageSize: 2);

        result.Data!.HasMore.Should().BeFalse();
    }

    [Fact]
    public async Task Rejects_a_negative_since_cursor()
    {
        var result = await CreateSut().GetChangesAsync("owner-1", since: -1, pageSize: 50);

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("Person.Since.Invalid");
        _personRepo.Verify(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<Person>>()), Times.Never);
    }
}
