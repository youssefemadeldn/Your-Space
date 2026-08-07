using Microsoft.Extensions.Localization;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications.PeopleSpecifications;
using YourSpace.Services.Helper;
using YourSpace.Services.Resources;
using YourSpace.Services.Services.PersonImageService.Dtos;
using YourSpace.Services.Services.StorageService;

namespace YourSpace.Services.Services.PersonImageService;

public class PersonImageService(
    IUnitOfWork unitOfWork,
    IR2StorageService r2StorageService,
    IOptions<R2Settings> r2Options,
    IStringLocalizer<SharedResource> localizer,
    ILogger<PersonImageService> logger) : IPersonImageService
{
    private const int MaxImagesPerPerson = 6;

    private static class ErrorCodes
    {
        public const string NotFound = "PersonImage.NotFound";
        public const string PersonNotFound = "Person.NotFound";
        public const string MaxReached = "PersonImage.MaxReached";
    }

    public async Task<ServiceResult<IReadOnlyList<PersonImageDto>>> GetAllAsync(string ownerUserId, int personId)
    {
        if (!await PersonExistsAsync(personId, ownerUserId))
        {
            logger.LogWarning("Person {PersonId} not found for user {UserId}", personId, ownerUserId);
            return ServiceResult<IReadOnlyList<PersonImageDto>>.NotFound(localizer["Person.NotFound"], ErrorCodes.PersonNotFound);
        }

        var repo = unitOfWork.Repository<PersonImage, int>();
        var images = await repo.ListAllWithSpecAsync(PersonImageWithSpecs.ForPerson(personId, ownerUserId));

        var dtos = await ToDtosAsync(images);
        return ServiceResult<IReadOnlyList<PersonImageDto>>.Ok(dtos);
    }

    public async Task<ServiceResult<PersonImageDto>> UploadAsync(string ownerUserId, int personId, UploadPersonImageDto dto)
    {
        if (!await PersonExistsAsync(personId, ownerUserId))
        {
            logger.LogWarning("Upload image failed — person {PersonId} not found for user {UserId}", personId, ownerUserId);
            return ServiceResult<PersonImageDto>.NotFound(localizer["Person.NotFound"], ErrorCodes.PersonNotFound);
        }

        var repo = unitOfWork.Repository<PersonImage, int>();
        var existingCount = await repo.CountWithSpecAsync(PersonImageWithSpecs.ForPerson(personId, ownerUserId));
        if (existingCount >= MaxImagesPerPerson)
        {
            logger.LogWarning("Upload image rejected — person {PersonId} already has the max of {Max} images", personId, MaxImagesPerPerson);
            return ServiceResult<PersonImageDto>.Fail(localizer["PersonImage.MaxReached"], ErrorCodes.MaxReached, 400);
        }

        var bucketName = r2Options.Value.PeoplePhotosBucketName;
        var objectKey = $"people/{personId}/{Guid.NewGuid()}{ExtensionFor(dto.File.ContentType)}";
        await r2StorageService.UploadAsync(bucketName, objectKey, dto.File);

        var image = new PersonImage
        {
            PersonId = personId,
            ObjectKey = objectKey,
            // The first image for a person is auto-marked primary, so a person with at least one photo
            // never has zero flagged primary — matches "one marked primary" from the original spec.
            IsPrimary = existingCount == 0
        };

        await repo.AddAsync(image);
        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("Image uploaded for person {PersonId}, user {UserId}", personId, ownerUserId);
        var url = await r2StorageService.GetPresignedUrlAsync(bucketName, objectKey);
        return ServiceResult<PersonImageDto>.Created(ToDto(image, url));
    }

    public async Task<ServiceResult> DeleteAsync(string ownerUserId, int personId, int imageId)
    {
        var repo = unitOfWork.Repository<PersonImage, int>();
        var image = await repo.GetByIdWithSpecAsync(PersonImageWithSpecs.ById(imageId, personId, ownerUserId));

        if (image is null)
        {
            logger.LogWarning("Image {ImageId} not found for person {PersonId}, user {UserId}", imageId, personId, ownerUserId);
            return ServiceResult.NotFound(localizer["PersonImage.NotFound"], ErrorCodes.NotFound);
        }

        var wasPrimary = image.IsPrimary;
        var transaction = await unitOfWork.BeginTransactionAsync();
        try
        {
            repo.Delete(image);
            await unitOfWork.SaveChangesAsync();

            if (wasPrimary)
            {
                var remaining = await repo.ListAllWithSpecAsync(PersonImageWithSpecs.ForPerson(personId, ownerUserId));
                var promoted = remaining.OrderBy(i => i.CreatedAt).FirstOrDefault();
                if (promoted is not null)
                {
                    promoted.IsPrimary = true;
                    promoted.UpdatedAt = DateTime.UtcNow;
                    repo.Update(promoted);
                    await unitOfWork.SaveChangesAsync();
                }
            }

            await unitOfWork.CommitAsync(transaction);
        }
        catch
        {
            await unitOfWork.RollbackAsync(transaction);
            throw;
        }

        // Only after the DB transaction commits — a failed R2 delete at this point only leaks a
        // harmless orphaned object, never leaves a DB row pointing at a deleted file.
        try
        {
            await r2StorageService.DeleteAsync(r2Options.Value.PeoplePhotosBucketName, image.ObjectKey);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to delete R2 object {ObjectKey} for image {ImageId}", image.ObjectKey, imageId);
        }

        logger.LogInformation("Image {ImageId} deleted for person {PersonId}, user {UserId}", imageId, personId, ownerUserId);
        return ServiceResult.Ok("Image deleted successfully.");
    }

    public async Task<ServiceResult<PersonImageDto>> SetPrimaryAsync(string ownerUserId, int personId, int imageId)
    {
        var repo = unitOfWork.Repository<PersonImage, int>();
        var image = await repo.GetByIdWithSpecAsync(PersonImageWithSpecs.ById(imageId, personId, ownerUserId));

        if (image is null)
        {
            logger.LogWarning("Image {ImageId} not found for person {PersonId}, user {UserId}", imageId, personId, ownerUserId);
            return ServiceResult<PersonImageDto>.NotFound(localizer["PersonImage.NotFound"], ErrorCodes.NotFound);
        }

        if (!image.IsPrimary)
        {
            var transaction = await unitOfWork.BeginTransactionAsync();
            try
            {
                var siblings = await repo.ListAllWithSpecAsync(PersonImageWithSpecs.ForPerson(personId, ownerUserId));
                var currentPrimary = siblings.FirstOrDefault(i => i.IsPrimary && i.Id != image.Id);
                if (currentPrimary is not null)
                {
                    currentPrimary.IsPrimary = false;
                    currentPrimary.UpdatedAt = DateTime.UtcNow;
                    repo.Update(currentPrimary);
                }

                image.IsPrimary = true;
                image.UpdatedAt = DateTime.UtcNow;
                repo.Update(image);

                await unitOfWork.SaveChangesAsync();
                await unitOfWork.CommitAsync(transaction);
            }
            catch
            {
                await unitOfWork.RollbackAsync(transaction);
                throw;
            }
        }

        logger.LogInformation("Image {ImageId} set as primary for person {PersonId}, user {UserId}", imageId, personId, ownerUserId);
        var url = await r2StorageService.GetPresignedUrlAsync(r2Options.Value.PeoplePhotosBucketName, image.ObjectKey);
        return ServiceResult<PersonImageDto>.Ok(ToDto(image, url));
    }

    private async Task<bool> PersonExistsAsync(int personId, string ownerUserId)
    {
        var personRepo = unitOfWork.Repository<Person, int>();
        return await personRepo.GetByIdWithSpecAsync(new PersonWithSpecs(personId, ownerUserId)) is not null;
    }

    private async Task<IReadOnlyList<PersonImageDto>> ToDtosAsync(IReadOnlyList<PersonImage> images)
    {
        var dtos = new List<PersonImageDto>(images.Count);
        foreach (var image in images)
        {
            var url = await r2StorageService.GetPresignedUrlAsync(r2Options.Value.PeoplePhotosBucketName, image.ObjectKey);
            dtos.Add(ToDto(image, url));
        }

        return dtos;
    }

    private static PersonImageDto ToDto(PersonImage image, string url) => new()
    {
        Id = image.Id,
        Url = url,
        IsPrimary = image.IsPrimary,
        CreatedAt = image.CreatedAt
    };

    private static string ExtensionFor(string contentType) => contentType switch
    {
        "image/png" => ".png",
        _ => ".jpg"
    };
}
