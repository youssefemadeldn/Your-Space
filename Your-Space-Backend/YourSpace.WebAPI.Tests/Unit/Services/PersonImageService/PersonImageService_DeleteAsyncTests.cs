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

public class PersonImageService_DeleteAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<PersonImage, int>> _imageRepo = new();
    private readonly Mock<IR2StorageService> _r2Storage = new();

    public PersonImageService_DeleteAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<PersonImage, int>()).Returns(_imageRepo.Object);
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

        var result = await CreateSut().DeleteAsync("owner-1", personId: 10, imageId: 99);

        result.Success.Should().BeFalse();
        result.ErrorCode.Should().Be("PersonImage.NotFound");
    }

    [Fact]
    public async Task Deleting_a_non_primary_image_leaves_the_existing_primary_untouched()
    {
        var target = new PersonImage { Id = 2, PersonId = 10, ObjectKey = "people/10/b.jpg", IsPrimary = false };
        _imageRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<PersonImage>>())).ReturnsAsync(target);

        var result = await CreateSut().DeleteAsync("owner-1", personId: 10, imageId: 2);

        result.Success.Should().BeTrue();
        _imageRepo.Verify(r => r.Delete(target), Times.Once);
        _imageRepo.Verify(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<PersonImage>>()), Times.Never);
        _imageRepo.Verify(r => r.Update(It.IsAny<PersonImage>()), Times.Never);
    }

    [Fact]
    public async Task Deleting_the_primary_image_promotes_the_oldest_remaining_image()
    {
        var target = new PersonImage { Id = 1, PersonId = 10, ObjectKey = "people/10/a.jpg", IsPrimary = true, CreatedAt = DateTime.UtcNow.AddDays(-2) };
        var remaining = new PersonImage { Id = 2, PersonId = 10, ObjectKey = "people/10/b.jpg", IsPrimary = false, CreatedAt = DateTime.UtcNow.AddDays(-1) };
        _imageRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<PersonImage>>())).ReturnsAsync(target);
        _imageRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<PersonImage>>())).ReturnsAsync([remaining]);

        var result = await CreateSut().DeleteAsync("owner-1", personId: 10, imageId: 1);

        result.Success.Should().BeTrue();
        remaining.IsPrimary.Should().BeTrue();
        _imageRepo.Verify(r => r.Update(remaining), Times.Once);
        _r2Storage.Verify(s => s.DeleteAsync("people", "people/10/a.jpg", It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task Deleting_the_only_image_leaves_no_primary_to_promote()
    {
        var target = new PersonImage { Id = 1, PersonId = 10, ObjectKey = "people/10/a.jpg", IsPrimary = true };
        _imageRepo.Setup(r => r.GetByIdWithSpecAsync(It.IsAny<ISpecification<PersonImage>>())).ReturnsAsync(target);
        _imageRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<PersonImage>>())).ReturnsAsync([]);

        var result = await CreateSut().DeleteAsync("owner-1", personId: 10, imageId: 1);

        result.Success.Should().BeTrue();
        _imageRepo.Verify(r => r.Update(It.IsAny<PersonImage>()), Times.Never);
    }
}
