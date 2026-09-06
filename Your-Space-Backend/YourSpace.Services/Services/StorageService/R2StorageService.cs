using Amazon.S3;
using Amazon.S3.Model;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Options;

namespace YourSpace.Services.Services.StorageService;

public class R2StorageService(IAmazonS3 s3Client, IOptions<R2Settings> options) : IR2StorageService
{
    public async Task UploadAsync(string bucketName, string objectKey, IFormFile file, CancellationToken ct = default)
    {
        await using var stream = file.OpenReadStream();
        var request = new PutObjectRequest
        {
            BucketName = bucketName,
            Key = objectKey,
            InputStream = stream,
            ContentType = file.ContentType,
            AutoCloseStream = false,
            // R2 doesn't implement AWS's chunked/streaming SigV4 payload formats (confirmed via a live
            // smoke test — "STREAMING-AWS4-HMAC-SHA256-PAYLOAD[-TRAILER] not implemented"), which the SDK
            // otherwise defaults to for stream-bodied PutObject requests. Falling back to a single signed
            // (non-chunked) payload is what R2 actually supports; safe only over HTTPS, which R2 always is.
            UseChunkEncoding = false,
            DisablePayloadSigning = true
        };

        await s3Client.PutObjectAsync(request, ct);
    }

    public async Task DeleteAsync(string bucketName, string objectKey, CancellationToken ct = default)
    {
        await s3Client.DeleteObjectAsync(new DeleteObjectRequest { BucketName = bucketName, Key = objectKey }, ct);
    }

    public Task<string> GetPresignedUrlAsync(string bucketName, string objectKey)
    {
        var request = new GetPreSignedUrlRequest
        {
            BucketName = bucketName,
            Key = objectKey,
            Verb = HttpVerb.GET,
            Expires = DateTime.UtcNow.AddHours(options.Value.PresignedUrlExpiryHours)
        };

        return s3Client.GetPreSignedURLAsync(request);
    }
}
