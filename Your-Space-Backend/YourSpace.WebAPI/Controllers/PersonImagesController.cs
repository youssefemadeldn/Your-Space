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
    // Flat "all mine" pull (row 9.15/9.16, design doc §6) — person-agnostic, feeds the mobile
    // client's Tier 1 local bookkeeping cache and (row 9.18) its permanent full-refetch-as-delta
    // Tier 3 pull. Same `~/api/v{version:apiVersion}/` absolute-path override convention as
    // Cities/SubGroups/EventGuests/PersonRelationships.
    [HttpGet("~/api/v{version:apiVersion}/person-images")]
    public async Task<IActionResult> GetAllMine()
    {
        var result = await personImageService.GetAllMineAsync(GetUserId());
        return new ResultActionResult<List<PersonImageProfileDto>>(result);
    }

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
