using FluentAssertions;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Services.Services.StorageService;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using PersonImageServiceImpl = YourSpace.Services.Services.PersonImageService.PersonImageService;

namespace YourSpace.WebAPI.Tests.Unit.Services.PersonImageService;

public class PersonImageService_GetAllAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<PersonImage, int>> _imageRepo = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();
    private readonly Mock<IR2StorageService> _r2Storage = new();

    public PersonImageService_GetAllAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<PersonImage, int>()).Returns(_imageRepo.Object);
        _unitOfWork.Setup(u => u.Repository<Person, int>()).Returns(_personRepo.Object);
        _r2Storage.Setup(s => s.GetPresignedUrlAsync(It.IsAny<string>(), It.IsAny<string>()))
            .ReturnsAsync((string bucket, string key) => $"https://fake/{bucket}/{key}");
    }

    private PersonImageServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        _r2Storage.Object,
        Options.Create(new R2Settings { AccountId = "test", AccessKey = "test", SecretKey = "test", AvatarsBucketName = "avatars", PeoplePhotosBucketName = "people" }),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<PersonImageServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_person_does_not_exist_for_owner()
    {
        _personRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync((Person?)null);

        var result = await CreateSut().GetAllAsync("owner-1", personId: 99);

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("Person.NotFound");
    }

    [Fact]
    public async Task Returns_presigned_urls_for_every_image()
    {
        _personRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Person>>()))
            .ReturnsAsync(new Person { Id = 10, OwnerUserId = "owner-1", Name = "Ahmed", Gender = Gender.Male, GroupId = 1, GovernorateId = 1 });
        _imageRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<PersonImage>>()))
            .ReturnsAsync([
                new PersonImage { Id = 1, PersonId = 10, ObjectKey = "people/10/a.jpg", IsPrimary = true }
            ]);

        var result = await CreateSut().GetAllAsync("owner-1", personId: 10);

        result.Success.Should().BeTrue();
        result.Data.Should().ContainSingle();
        result.Data![0].Url.Should().Be("https://fake/people/people/10/a.jpg");
        result.Data[0].IsPrimary.Should().BeTrue();
    }
}
