namespace YourSpace.Services.Services.PersonImageService.Dtos;

public class PersonImageDto
{
    public required int Id { get; set; }

    // Presigned, resolved in-service — never a plain AutoMapper member-map.
    public required string Url { get; set; }

    public required bool IsPrimary { get; set; }
    public required DateTime CreatedAt { get; set; }
}
