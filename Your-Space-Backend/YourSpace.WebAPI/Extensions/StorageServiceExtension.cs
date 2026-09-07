using Amazon.Runtime;
using Amazon.S3;
using Microsoft.Extensions.Options;
using YourSpace.Services.Services.StorageService;

namespace YourSpace.WebAPI.Extensions;

public static class StorageServiceExtension
{
    public static IServiceCollection AddR2StorageService(this IServiceCollection services, IConfiguration configuration)
    {
        services.Configure<R2Settings>(configuration.GetSection(R2Settings.SectionName));

        // IAmazonS3 is thread-safe and expensive to construct — shared app-wide, same posture as any
        // other cross-cutting infrastructure client (CLAUDE.md DI lifetime table). Wrapped in Lazy<T>
        // so the client is built on the first actual storage call, NOT at DI-resolution time:
        // R2StorageService is a constructor dependency of AuthService (avatar upload/remove), so a
        // blank/invalid R2 config would otherwise throw while resolving every auth endpoint — login
        // included — turning a storage misconfiguration into a total auth outage. Lazy<T> keeps the
        // blast radius to the operations that genuinely need R2.
        services.AddSingleton(sp => new Lazy<IAmazonS3>(() =>
        {
            var r2Settings = sp.GetRequiredService<IOptions<R2Settings>>().Value;

            var config = new AmazonS3Config
            {
                ServiceURL = $"https://{r2Settings.AccountId}.r2.cloudflarestorage.com",
                ForcePathStyle = true,
                // R2 ignores the region but the SDK requires one to be set.
                AuthenticationRegion = "auto",
                // AWSSDK.S3 v4's default (WHEN_SUPPORTED) signs PutObject request bodies using the
                // newer STREAMING-AWS4-HMAC-SHA256-PAYLOAD-TRAILER format, which R2 does not implement
                // ("STREAMING-AWS4-HMAC-SHA256-PAYLOAD-TRAILER not implemented" — confirmed via a live
                // smoke test against the real bucket). WHEN_REQUIRED falls back to the older signing
                // format R2 actually supports.
                RequestChecksumCalculation = RequestChecksumCalculation.WHEN_REQUIRED,
                ResponseChecksumValidation = ResponseChecksumValidation.WHEN_REQUIRED
            };

            return new AmazonS3Client(r2Settings.AccessKey, r2Settings.SecretKey, config);
        }));

        services.AddSingleton<IR2StorageService, R2StorageService>();

        return services;
    }
}
