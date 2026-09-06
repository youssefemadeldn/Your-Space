using Microsoft.AspNetCore.Http;

namespace YourSpace.Services.Services.AuthService.Dtos;

// Bound via [FromForm] — multipart, not JSON.
public class UploadAvatarDto
{
    public required IFormFile File { get; set; }
}
