using Microsoft.AspNetCore.Http;

namespace YourSpace.Services.Services.PersonImageService.Dtos;

// No PersonId — it comes from the nested route (/persons/{personId}/images), not the body.
// Bound via [FromForm] — multipart, not JSON.
public class UploadPersonImageDto
{
    public required IFormFile File { get; set; }
}
