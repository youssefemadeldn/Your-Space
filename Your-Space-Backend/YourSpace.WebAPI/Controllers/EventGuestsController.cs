using System.Security.Claims;
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YourSpace.Data.Enums;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.EventGuestService;
using YourSpace.Services.Services.EventGuestService.Dtos;
using YourSpace.Services.Services.PersonService.Dtos;
using YourSpace.WebAPI.Helpers;

namespace YourSpace.WebAPI.Controllers;

// The guest-building workflow for one Event — kept as its own controller/service, separate from
// EventsController's plain CRUD, since bulk-add/status-transitions/progress/reciprocity is a much
// larger surface that would otherwise turn EventService into a god-class.
[ApiController]
[ApiVersion("1.0")]
[Authorize]
[Route("api/v{version:apiVersion}/events/{eventId:int}/guests")]
public class EventGuestsController(IEventGuestService eventGuestService) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetList(
        int eventId, [FromQuery] int? groupId, [FromQuery] EventGuestStatus? status, [FromQuery] PaginationSpecification pagination)
    {
        var result = await eventGuestService.GetListAsync(GetUserId(), eventId, groupId, status, pagination);
        return new ResultActionResult<PaginatedResultDto<EventGuestProfileDto>>(result);
    }

    [HttpGet("progress")]
    public async Task<IActionResult> GetProgress(int eventId)
    {
        var result = await eventGuestService.GetProgressAsync(GetUserId(), eventId);
        return new ResultActionResult<EventGuestProgressSummaryDto>(result);
    }

    [HttpGet("reciprocity-suggestions")]
    public async Task<IActionResult> GetReciprocitySuggestions(int eventId, [FromQuery] int? groupId, [FromQuery] PaginationSpecification pagination)
    {
        var result = await eventGuestService.GetReciprocitySuggestionsAsync(GetUserId(), eventId, groupId, pagination);
        return new ResultActionResult<PaginatedResultDto<PersonProfileDto>>(result);
    }

    [HttpGet("{guestId:int}")]
    public async Task<IActionResult> GetDetails(int eventId, int guestId)
    {
        var result = await eventGuestService.GetDetailsAsync(GetUserId(), eventId, guestId);
        return new ResultActionResult<EventGuestDetailsDto>(result);
    }

    [HttpPost]
    public async Task<IActionResult> AddPersons(int eventId, [FromBody] AddPersonsToEventDto dto)
    {
        var result = await eventGuestService.AddPersonsAsync(GetUserId(), eventId, dto);
        return new ResultActionResult<BulkAddGuestsResultDto>(result);
    }

    [HttpPost("by-group/{groupId:int}")]
    public async Task<IActionResult> AddGroup(int eventId, int groupId)
    {
        var result = await eventGuestService.AddGroupAsync(GetUserId(), eventId, groupId);
        return new ResultActionResult<BulkAddGuestsResultDto>(result);
    }

    [HttpPost("by-subgroup/{subGroupId:int}")]
    public async Task<IActionResult> AddSubGroup(int eventId, int subGroupId)
    {
        var result = await eventGuestService.AddSubGroupAsync(GetUserId(), eventId, subGroupId);
        return new ResultActionResult<BulkAddGuestsResultDto>(result);
    }

    [HttpPost("by-governorate/{governorateId:int}")]
    public async Task<IActionResult> AddGovernorate(int eventId, int governorateId)
    {
        var result = await eventGuestService.AddGovernorateAsync(GetUserId(), eventId, governorateId);
        return new ResultActionResult<BulkAddGuestsResultDto>(result);
    }

    [HttpPost("by-city/{cityId:int}")]
    public async Task<IActionResult> AddCity(int eventId, int cityId)
    {
        var result = await eventGuestService.AddCityAsync(GetUserId(), eventId, cityId);
        return new ResultActionResult<BulkAddGuestsResultDto>(result);
    }

    [HttpPost("by-neighborhood/{neighborhoodId:int}")]
    public async Task<IActionResult> AddNeighborhood(int eventId, int neighborhoodId)
    {
        var result = await eventGuestService.AddNeighborhoodAsync(GetUserId(), eventId, neighborhoodId);
        return new ResultActionResult<BulkAddGuestsResultDto>(result);
    }

    [HttpPost("{guestId:int}/invite")]
    public async Task<IActionResult> MarkInvited(int eventId, int guestId, [FromBody] MarkGuestInvitedDto dto)
    {
        var result = await eventGuestService.MarkInvitedAsync(GetUserId(), eventId, guestId, dto);
        return new ResultActionResult<EventGuestDetailsDto>(result);
    }

    [HttpPost("{guestId:int}/skip")]
    public async Task<IActionResult> MarkSkipped(int eventId, int guestId)
    {
        var result = await eventGuestService.MarkSkippedAsync(GetUserId(), eventId, guestId);
        return new ResultActionResult<EventGuestDetailsDto>(result);
    }

    [HttpPost("{guestId:int}/revert")]
    public async Task<IActionResult> Revert(int eventId, int guestId)
    {
        var result = await eventGuestService.RevertAsync(GetUserId(), eventId, guestId);
        return new ResultActionResult<EventGuestDetailsDto>(result);
    }

    [HttpDelete("{guestId:int}")]
    public async Task<IActionResult> Remove(int eventId, int guestId)
    {
        var result = await eventGuestService.RemoveGuestAsync(GetUserId(), eventId, guestId);
        return new ResultActionResult(result);
    }

    private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier)!;
}
