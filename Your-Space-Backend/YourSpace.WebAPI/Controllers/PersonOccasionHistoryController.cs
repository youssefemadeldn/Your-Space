using System.Security.Claims;
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.PersonOccasionHistoryService;
using YourSpace.Services.Services.PersonOccasionHistoryService.Dtos;
using YourSpace.WebAPI.Helpers;

namespace YourSpace.WebAPI.Controllers;

// Reciprocity history for one Person — kept as its own controller/service rather than bolted onto
// PersonsController, since it's a distinct responsibility (CLAUDE.md "split when a class takes on
// a second, unrelated responsibility").
[ApiController]
[ApiVersion("1.0")]
[Authorize]
[Route("api/v{version:apiVersion}/persons/{personId:int}/occasion-history")]
public class PersonOccasionHistoryController(IPersonOccasionHistoryService historyService) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll(int personId, [FromQuery] PaginationSpecification pagination)
    {
        var result = await historyService.GetAllAsync(GetUserId(), personId, pagination);
        return new ResultActionResult<PaginatedResultDto<PersonOccasionHistoryProfileDto>>(result);
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetDetails(int personId, int id)
    {
        var result = await historyService.GetDetailsAsync(GetUserId(), personId, id);
        return new ResultActionResult<PersonOccasionHistoryDetailsDto>(result);
    }

    [HttpPost]
    public async Task<IActionResult> Create(int personId, [FromBody] CreatePersonOccasionHistoryDto dto)
    {
        var result = await historyService.CreateAsync(GetUserId(), personId, dto);
        return new ResultActionResult<PersonOccasionHistoryDetailsDto>(result);
    }

    [HttpPut]
    public async Task<IActionResult> Update(int personId, [FromBody] UpdatePersonOccasionHistoryDto dto)
    {
        var result = await historyService.UpdateAsync(GetUserId(), personId, dto);
        return new ResultActionResult<PersonOccasionHistoryDetailsDto>(result);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int personId, int id)
    {
        var result = await historyService.DeleteAsync(GetUserId(), personId, id);
        return new ResultActionResult(result);
    }

    private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier)!;
}
