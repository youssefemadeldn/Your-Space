using Microsoft.AspNetCore.Http;

namespace YourSpace.Services.Services.StorageService;

// Thin wrapper over the S3-compatible R2 client — a stateless singleton (CLAUDE.md DI lifetime table:
// no DbContext dependency, safe to share app-wide). Buckets stay private; every read goes through
// GetPresignedUrlAsync, never a public URL.
public interface IR2StorageService
{
    Task UploadAsync(string bucketName, string objectKey, IFormFile file, CancellationToken ct = default);

    Task DeleteAsync(string bucketName, string objectKey, CancellationToken ct = default);

    // Presigned-URL generation is a local HMAC signature computation, not a network round trip —
    // cheap enough to call on every profile/person read despite the async signature.
    Task<string> GetPresignedUrlAsync(string bucketName, string objectKey);
}
