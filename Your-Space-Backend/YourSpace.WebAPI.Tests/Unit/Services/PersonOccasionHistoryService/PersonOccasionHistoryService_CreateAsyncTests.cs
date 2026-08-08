using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Services.Services.PersonOccasionHistoryService.Dtos;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using PersonOccasionHistoryServiceImpl = YourSpace.Services.Services.PersonOccasionHistoryService.PersonOccasionHistoryService;

namespace YourSpace.WebAPI.Tests.Unit.Services.PersonOccasionHistoryService;

public class PersonOccasionHistoryService_CreateAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<PersonOccasionHistory, int>> _historyRepo = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();

    public PersonOccasionHistoryService_CreateAsyncTests()
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

        var result = await CreateSut().CreateAsync("owner-1", personId: 99, new CreatePersonOccasionHistoryDto { InvitedMe = true, InviteMethod = InviteMethod.WhatsApp });

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("Person.NotFound");
        _historyRepo.Verify(r => r.AddAsync(It.IsAny<PersonOccasionHistory>()), Times.Never);
    }

    [Fact]
    public async Task Forces_invite_method_null_when_invited_me_is_false_even_if_supplied()
    {
        _personRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Person>>()))
            .ReturnsAsync(new Person { Id = 10, OwnerUserId = "owner-1", Name = "Ahmed", Gender = Gender.Male, GroupId = 1, GovernorateId = 1 });

        var result = await CreateSut().CreateAsync("owner-1", personId: 10,
            new CreatePersonOccasionHistoryDto { InvitedMe = false, InviteMethod = InviteMethod.WhatsApp });

        result.Success.Should().BeTrue();
        result.Data!.InviteMethod.Should().BeNull();
    }
}
