namespace YourSpace.Services.Services.StorageService;

public class R2Settings
{
    public const string SectionName = "R2";

    public required string AccountId { get; set; }
    public required string AccessKey { get; set; }
    public required string SecretKey { get; set; }
    public required string AvatarsBucketName { get; set; }
    public required string PeoplePhotosBucketName { get; set; }
    public int PresignedUrlExpiryHours { get; set; } = 24;
}
