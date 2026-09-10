using FluentAssertions;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Moq;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;
using YourSpace.Services.Services.StorageService;
using YourSpace.WebAPI.Tests.Common.MockFactories;
using PersonImageServiceImpl = YourSpace.Services.Services.PersonImageService.PersonImageService;

namespace YourSpace.WebAPI.Tests.Unit.Services.PersonImageService;

public class PersonImageService_SetPrimaryAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<PersonImage, int>> _imageRepo = new();
    private readonly Mock<IR2StorageService> _r2Storage = new();

    public PersonImageService_SetPrimaryAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<PersonImage, int>()).Returns(_imageRepo.Object);
        _r2Storage.Setup(s => s.GetPresignedUrlAsync(It.IsAny<string>(), It.IsAny<string>())).ReturnsAsync("https://fake/url");
    }

    private PersonImageServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        _r2Storage.Object,
        Options.Create(new R2Settings { AccountId = "test", AccessKey = "test", SecretKey = "test", AvatarsBucketName = "avatars", PeoplePhotosBucketName = "people" }),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<PersonImageServiceImpl>>());

    [Fact]
    public async Task Returns_not_found_when_image_does_not_exist()
    {
        _imageRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<PersonImage>>())).ReturnsAsync((PersonImage?)null);

        var result = await CreateSut().SetPrimaryAsync("owner-1", personId: 10, imageId: 99);

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("PersonImage.NotFound");
    }

    [Fact]
    public async Task Already_primary_image_is_a_no_op()
    {
        var image = new PersonImage { Id = 1, PersonId = 10, ObjectKey = "people/10/a.jpg", IsPrimary = true };
        _imageRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<PersonImage>>())).ReturnsAsync(image);

        var result = await CreateSut().SetPrimaryAsync("owner-1", personId: 10, imageId: 1);

        result.Success.Should().BeTrue();
        _imageRepo.Verify(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<PersonImage>>()), Times.Never);
    }

    [Fact]
    public async Task Setting_a_new_primary_clears_the_old_one()
    {
        var oldPrimary = new PersonImage { Id = 1, PersonId = 10, ObjectKey = "people/10/a.jpg", IsPrimary = true };
        var target = new PersonImage { Id = 2, PersonId = 10, ObjectKey = "people/10/b.jpg", IsPrimary = false };
        _imageRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<PersonImage>>())).ReturnsAsync(target);
        _imageRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<PersonImage>>())).ReturnsAsync([oldPrimary, target]);

        var result = await CreateSut().SetPrimaryAsync("owner-1", personId: 10, imageId: 2);

        result.Success.Should().BeTrue();
        oldPrimary.IsPrimary.Should().BeFalse();
        target.IsPrimary.Should().BeTrue();
        _imageRepo.Verify(r => r.Update(oldPrimary), Times.Once);
        _imageRepo.Verify(r => r.Update(target), Times.Once);
    }
}
