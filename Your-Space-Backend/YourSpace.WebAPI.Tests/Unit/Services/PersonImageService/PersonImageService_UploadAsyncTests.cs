using FluentAssertions;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Services.Services.PersonImageService.Dtos;
using YourSpace.Services.Services.StorageService;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using PersonImageServiceImpl = YourSpace.Services.Services.PersonImageService.PersonImageService;

namespace YourSpace.WebAPI.Tests.Unit.Services.PersonImageService;

public class PersonImageService_UploadAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<PersonImage, int>> _imageRepo = new();
    private readonly Mock<IGenericRepository<Person, int>> _personRepo = new();
    private readonly Mock<IR2StorageService> _r2Storage = new();

    private static readonly Person Owner = new() { Id = 10, OwnerUserId = "owner-1", Name = "Ahmed", Gender = Gender.Male, GroupId = 1, GovernorateId = 1 };

    public PersonImageService_UploadAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<PersonImage, int>()).Returns(_imageRepo.Object);
        _unitOfWork.Setup(u => u.Repository<Person, int>()).Returns(_personRepo.Object);
        _personRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync(Owner);
        _r2Storage.Setup(s => s.GetPresignedUrlAsync(It.IsAny<string>(), It.IsAny<string>())).ReturnsAsync("https://fake/url");
    }

    private PersonImageServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        _r2Storage.Object,
        Options.Create(new R2Settings { AccountId = "test", AccessKey = "test", SecretKey = "test", AvatarsBucketName = "avatars", PeoplePhotosBucketName = "people" }),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<PersonImageServiceImpl>>());

    private static UploadPersonImageDto MakeDto()
    {
        var file = new Mock<IFormFile>();
        file.Setup(f => f.ContentType).Returns("image/jpeg");
        file.Setup(f => f.Length).Returns(1024);
        return new UploadPersonImageDto { File = file.Object };
    }

    [Fact]
    public async Task Returns_not_found_when_person_does_not_exist_for_owner()
    {
        _personRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<Person>>())).ReturnsAsync((Person?)null);

        var result = await CreateSut().UploadAsync("owner-1", personId: 99, MakeDto());

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("Person.NotFound");
    }

    [Fact]
    public async Task Rejects_upload_when_person_already_has_six_images()
    {
        _imageRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<PersonImage>>())).ReturnsAsync(6);

        var result = await CreateSut().UploadAsync("owner-1", personId: 10, MakeDto());

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("PersonImage.MaxReached");
        _r2Storage.Verify(s => s.UploadAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<IFormFile>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task First_image_for_a_person_is_auto_marked_primary()
    {
        _imageRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<PersonImage>>())).ReturnsAsync(0);

        var result = await CreateSut().UploadAsync("owner-1", personId: 10, MakeDto());

        result.Success.Should().BeTrue();
        result.Data!.IsPrimary.Should().BeTrue();
        _r2Storage.Verify(s => s.UploadAsync("people", It.IsAny<string>(), It.IsAny<IFormFile>(), It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task Second_image_for_a_person_is_not_marked_primary()
    {
        _imageRepo.Setup(r => r.CountWithSpecAsync(It.IsAny<ISpecification<PersonImage>>())).ReturnsAsync(1);

        var result = await CreateSut().UploadAsync("owner-1", personId: 10, MakeDto());

        result.Success.Should().BeTrue();
        result.Data!.IsPrimary.Should().BeFalse();
    }
}
