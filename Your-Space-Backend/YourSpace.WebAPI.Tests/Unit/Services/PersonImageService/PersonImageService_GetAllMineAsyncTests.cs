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

public class PersonImageService_GetAllMineAsyncTests
{
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IGenericRepository<PersonImage, int>> _imageRepo = new();
    private readonly Mock<IR2StorageService> _r2StorageService = new();

    public PersonImageService_GetAllMineAsyncTests()
    {
        _unitOfWork.Setup(u => u.Repository<PersonImage, int>()).Returns(_imageRepo.Object);
    }

    private PersonImageServiceImpl CreateSut() => new(
        _unitOfWork.Object,
        _r2StorageService.Object,
        Options.Create(new R2Settings { AccountId = "test", AccessKey = "test", SecretKey = "test", AvatarsBucketName = "avatars", PeoplePhotosBucketName = "people" }),
        LocalizerMockFactory.Create().Object,
        Mock.Of<ILogger<PersonImageServiceImpl>>());

    [Fact]
    public async Task Returns_every_image_row_across_every_person_the_owner_has_with_objectKey_not_a_presigned_url()
    {
        var image = new PersonImage { Id = 1, PersonId = 10, ObjectKey = "people/10/abc.jpg", IsPrimary = true };
        _imageRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<PersonImage>>())).ReturnsAsync([image]);

        var result = await CreateSut().GetAllMineAsync("owner-1");

        result.Success.Should().BeTrue();
        var dto = result.Data!.Single();
        dto.Id.Should().Be(1);
        dto.PersonId.Should().Be(10);
        dto.ObjectKey.Should().Be("people/10/abc.jpg");
        dto.IsPrimary.Should().BeTrue();
        // Never resolves a presigned URL for the bulk endpoint — that would go stale in minutes.
        _r2StorageService.VerifyNoOtherCalls();
    }

    [Fact]
    public async Task Returns_an_empty_list_when_the_owner_has_no_images()
    {
        _imageRepo.Setup(r => r.ListAllWithSpecAsync(It.IsAny<ISpecification<PersonImage>>())).ReturnsAsync([]);

        var result = await CreateSut().GetAllMineAsync("owner-1");

        result.Success.Should().BeTrue();
        result.Data.Should().BeEmpty();
    }
}
