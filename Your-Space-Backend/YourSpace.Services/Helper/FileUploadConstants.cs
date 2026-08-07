namespace YourSpace.Services.Helper;

// Shared by every IFormFile upload validator (avatar, person photos) so the size/type rule can't
// drift between them.
public static class FileUploadConstants
{
    public static readonly string[] AllowedImageContentTypes = ["image/jpeg", "image/png"];
    public const long MaxImageSizeBytes = 5 * 1024 * 1024;
}
