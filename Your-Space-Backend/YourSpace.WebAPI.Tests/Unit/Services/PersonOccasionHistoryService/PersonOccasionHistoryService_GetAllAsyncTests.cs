using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using PersonOccasionHistoryServiceImpl = YourSpace.Services.Services.PersonOccasionHistoryService.PersonOccasionHistoryService;

namespace YourSpace.WebAPI.Tests.Unit.Services.PersonOccasionHistoryService;

public class PersonOccasionHistoryService_GetAllAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<PersonOccasionHistory, int>> _historyRepo = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();

    public PersonOccasionHistoryService_GetAllAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<PersonOccasionHistory, int>()).Returns(_historyRepo.Object);
        _unitOfWork.Setup(u => u.Repository<Person, int>()).Returns(_personRepo.Object);
    }

    private PersonOccasionHistoryServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        MapperFactory.Create(),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<PersonOccasionHistoryServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_person_does_not_exist_for_owner()
    {
        _personRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync((Person?)null);

        var result = await CreateSut().GetAllAsync("owner-1", personId: 99, new PaginationSpecification());

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("Person.NotFound");
    }
}
