using System.Security.Claims;
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.PersonImageService;
using YourSpace.Services.Services.PersonImageService.Dtos;
using YourSpace.WebAPI.Helpers;

namespace YourSpace.WebAPI.Controllers;

// Photos for one Person — kept as its own controller/service rather than bolted onto PersonsController,
// same precedent as PersonOccasionHistoryController (a distinct responsibility; CLAUDE.md "split when a
// class takes on a second, unrelated responsibility").
[ApiController]
[ApiVersion("1.0")]
[Authorize]
[Route("api/v{version:apiVersion}/persons/{personId:int}/images")]
public class PersonImagesController(IPersonImageService personImageService) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll(int personId)
    {
        var result = await personImageService.GetAllAsync(GetUserId(), personId);
        return new ResultActionResult<IReadOnlyList<PersonImageDto>>(result);
    }

    [HttpPost]
    public async Task<IActionResult> Upload(int personId, [FromForm] UploadPersonImageDto dto)
    {
        var result = await personImageService.UploadAsync(GetUserId(), personId, dto);
        return new ResultActionResult<PersonImageDto>(result);
    }

    [HttpDelete("{imageId:int}")]
    public async Task<IActionResult> Delete(int personId, int imageId)
    {
        var result = await personImageService.DeleteAsync(GetUserId(), personId, imageId);
        return new ResultActionResult(result);
    }

    [HttpPost("{imageId:int}/set-primary")]
    public async Task<IActionResult> SetPrimary(int personId, int imageId)
    {
        var result = await personImageService.SetPrimaryAsync(GetUserId(), personId, imageId);
        return new ResultActionResult<PersonImageDto>(result);
    }

    private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier)!;
}
