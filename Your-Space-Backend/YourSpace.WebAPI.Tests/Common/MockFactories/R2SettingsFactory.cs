using Microsoft.Extensions.Options;
using YourSpace.Services.Services.StorageService;

namespace YourSpace.WebAPI.Tests.Common.MockFactories;

// Every service resolving a presigned photo URL (PersonImageService, PersonService) takes
// IOptions<R2Settings> — tests never touch real R2, so the values just need to be non-null.
public static class R2SettingsFactory
{
    public static IOptions<R2Settings> Create() => Options.Create(new R2Settings
    {
        AccountId = "test-account",
        AccessKey = "test-access-key",
        SecretKey = "test-secret-key",
        AvatarsBucketName = "test-avatars",
        PeoplePhotosBucketName = "test-people-photos"
    });
}
