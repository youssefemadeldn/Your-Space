using System.Security.Claims;
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.EventService;
using YourSpace.Services.Services.EventService.Dtos;
using YourSpace.WebAPI.Helpers;

namespace YourSpace.WebAPI.Controllers;

[ApiController]
[ApiVersion("1.0")]
[Authorize]
[Route("api/v{version:apiVersion}/[controller]")]
public class EventsController(IEventService eventService) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] string? search, [FromQuery] PaginationSpecification pagination)
    {
        var result = await eventService.GetAllAsync(GetUserId(), search, pagination);
        return new ResultActionResult<PaginatedResultDto<EventProfileDto>>(result);
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetDetails(int id)
    {
        var result = await eventService.GetDetailsAsync(GetUserId(), id);
        return new ResultActionResult<EventDetailsDto>(result);
    }

    // Delta-sync pull (doc/local-first-sync-design.md §6) — row 9.5 of the delivery plan. `since`
    // is the caller's last-seen SyncVersion cursor (0 on a first-ever sync); `pageSize` is
    // clamped server-side in EventService.
    [HttpGet("changes")]
    public async Task<IActionResult> GetChanges([FromQuery] long since = 0, [FromQuery] int pageSize = 200)
    {
        var result = await eventService.GetChangesAsync(GetUserId(), since, pageSize);
        return new ResultActionResult<EventChangesDto>(result);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateEventDto dto)
    {
        var result = await eventService.CreateAsync(GetUserId(), dto);
        return new ResultActionResult<EventDetailsDto>(result);
    }

    [HttpPut]
    public async Task<IActionResult> Update([FromBody] UpdateEventDto dto)
    {
        var result = await eventService.UpdateAsync(GetUserId(), dto);
        return new ResultActionResult<EventDetailsDto>(result);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var result = await eventService.DeleteAsync(GetUserId(), id);
        return new ResultActionResult(result);
    }

    private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier)!;
}
