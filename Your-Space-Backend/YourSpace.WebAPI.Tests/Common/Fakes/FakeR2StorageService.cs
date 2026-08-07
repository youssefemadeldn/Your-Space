using Microsoft.AspNetCore.Http;
using YourSpace.Services.Services.StorageService;

namespace YourSpace.WebAPI.Tests.Common.Fakes;

public class FakeR2StorageService : IR2StorageService
{
    public List<(string BucketName, string ObjectKey)> UploadedObjects { get; } = [];
    public List<(string BucketName, string ObjectKey)> DeletedObjects { get; } = [];

    public Task UploadAsync(string bucketName, string objectKey, IFormFile file, CancellationToken ct = default)
    {
        UploadedObjects.Add((bucketName, objectKey));
        return Task.CompletedTask;
    }

    public Task DeleteAsync(string bucketName, string objectKey, CancellationToken ct = default)
    {
        DeletedObjects.Add((bucketName, objectKey));
        return Task.CompletedTask;
    }

    public Task<string> GetPresignedUrlAsync(string bucketName, string objectKey)
        => Task.FromResult($"https://fake-r2.test/{bucketName}/{objectKey}");
}
