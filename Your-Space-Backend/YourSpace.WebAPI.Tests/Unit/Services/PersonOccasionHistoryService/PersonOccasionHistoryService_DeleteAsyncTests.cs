using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using PersonOccasionHistoryServiceImpl = YourSpace.Services.Services.PersonOccasionHistoryService.PersonOccasionHistoryService;

namespace YourSpace.WebAPI.Tests.Unit.Services.PersonOccasionHistoryService;

public class PersonOccasionHistoryService_DeleteAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<PersonOccasionHistory, int>> _historyRepo = new();

    public PersonOccasionHistoryService_DeleteAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<PersonOccasionHistory, int>()).Returns(_historyRepo.Object);
    }

    private PersonOccasionHistoryServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<PersonOccasionHistoryServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_entry_does_not_exist()
    {
        _historyRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<PersonOccasionHistory>>())).ReturnsAsync((PersonOccasionHistory?)null);

        var result = await CreateSut().DeleteAsync("owner-1", personId: 10, id: 99);

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("PersonOccasionHistory.NotFound");
    }

    [Fact]
    public async Task Hard_deletes_the_entry_unlike_the_soft_deletable_master_data_entities()
    {
        var entry = new PersonOccasionHistory { Id = 1, PersonId = 10, InvitedMe = true };
        _historyRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<PersonOccasionHistory>>())).ReturnsAsync(entry);

        var result = await CreateSut().DeleteAsync("owner-1", personId: 10, id: 1);

        result.Success.Should().BeTrue();
        _historyRepo.Verify(r => r.Delete(entry), Times.Once);
    }
}
