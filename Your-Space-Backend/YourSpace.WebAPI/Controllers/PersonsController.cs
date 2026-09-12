using System.Security.Claims;
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.PersonService;
using YourSpace.Services.Services.PersonService.Dtos;
using YourSpace.WebAPI.Helpers;

namespace YourSpace.WebAPI.Controllers;

// Person is a shared/core entity — private to its owner. Every action here requires an
// authenticated caller.
[ApiController]
[ApiVersion("1.0")]
[Authorize]
[Route("api/v{version:apiVersion}/[controller]")]
public class PersonsController(IPersonService personService) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll(
        [FromQuery] int? groupId,
        [FromQuery] int? subGroupId,
        [FromQuery] int? governorateId,
        [FromQuery] int? cityId,
        [FromQuery] int? neighborhoodId,
        [FromQuery] string? search,
        [FromQuery] PaginationSpecification pagination)
    {
        var result = await personService.GetAllAsync(GetUserId(), groupId, subGroupId, governorateId, cityId, neighborhoodId, search, pagination);
        return new ResultActionResult<PaginatedResultDto<PersonProfileDto>>(result);
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetDetails(int id)
    {
        var result = await personService.GetDetailsAsync(GetUserId(), id);
        return new ResultActionResult<PersonDetailsDto>(result);
    }

    // Delta-sync pull (doc/local-first-sync-design.md §6) — row 5 of the delivery plan. `since`
    // is the caller's last-seen SyncVersion cursor (0 on a first-ever sync); `pageSize` is
    // clamped server-side in PersonService.
    [HttpGet("changes")]
    public async Task<IActionResult> GetChanges([FromQuery] long since = 0, [FromQuery] int pageSize = 200)
    {
        var result = await personService.GetChangesAsync(GetUserId(), since, pageSize);
        return new ResultActionResult<PersonChangesDto>(result);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreatePersonDto dto)
    {
        var result = await personService.CreateAsync(GetUserId(), dto);
        return new ResultActionResult<PersonDetailsDto>(result);
    }

    [HttpPut]
    public async Task<IActionResult> Update([FromBody] UpdatePersonDto dto)
    {
        var result = await personService.UpdateAsync(GetUserId(), dto);
        return new ResultActionResult<PersonDetailsDto>(result);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var result = await personService.DeleteAsync(GetUserId(), id);
        return new ResultActionResult(result);
    }

    private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier)!;
}
