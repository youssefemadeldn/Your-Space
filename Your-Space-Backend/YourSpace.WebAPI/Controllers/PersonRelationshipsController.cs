using System.Security.Claims;
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.PersonRelationshipService;
using YourSpace.Services.Services.PersonRelationshipService.Dtos;
using YourSpace.WebAPI.Helpers;

namespace YourSpace.WebAPI.Controllers;

// Sibling to PersonsController, matching the PersonImagesController/PersonOccasionHistoryController
// precedent for a Person-sub-resource controller. Every relation is scoped to the caller's own
// People — both PersonId and RelatedPersonId are validated against ownerUserId in the service.
[ApiController]
[ApiVersion("1.0")]
[Authorize]
[Route("api/v{version:apiVersion}/persons/{personId:int}/relationships")]
public class PersonRelationshipsController(IPersonRelationshipService personRelationshipService) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll(int personId)
    {
        var result = await personRelationshipService.GetAllAsync(GetUserId(), personId);
        return new ResultActionResult<IReadOnlyList<PersonRelationshipProfileDto>>(result);
    }

    [HttpPost]
    public async Task<IActionResult> Create(int personId, [FromBody] CreatePersonRelationshipDto dto)
    {
        var result = await personRelationshipService.CreateAsync(GetUserId(), personId, dto);
        return new ResultActionResult<PersonRelationshipDetailsDto>(result);
    }

    [HttpDelete("{relationshipId:int}")]
    public async Task<IActionResult> Delete(int personId, int relationshipId)
    {
        var result = await personRelationshipService.DeleteAsync(GetUserId(), personId, relationshipId);
        return new ResultActionResult(result);
    }

    private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier)!;
}
