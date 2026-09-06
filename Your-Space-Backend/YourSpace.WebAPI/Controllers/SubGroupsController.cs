using System.Security.Claims;
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.SubGroupService;
using YourSpace.Services.Services.SubGroupService.Dtos;
using YourSpace.WebAPI.Helpers;

namespace YourSpace.WebAPI.Controllers;

// Nested under its parent Group — every SubGroup is scoped to exactly one Group.
[ApiController]
[ApiVersion("1.0")]
[Authorize]
[Route("api/v{version:apiVersion}/groups/{groupId:int}/subgroups")]
public class SubGroupsController(ISubGroupService subGroupService) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll(int groupId, [FromQuery] string? search, [FromQuery] PaginationSpecification pagination)
    {
        var result = await subGroupService.GetAllAsync(GetUserId(), groupId, search, pagination);
        return new ResultActionResult<PaginatedResultDto<SubGroupProfileDto>>(result);
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetDetails(int groupId, int id)
    {
        var result = await subGroupService.GetDetailsAsync(GetUserId(), groupId, id);
        return new ResultActionResult<SubGroupDetailsDto>(result);
    }

    [HttpPost]
    public async Task<IActionResult> Create(int groupId, [FromBody] CreateSubGroupDto dto)
    {
        var result = await subGroupService.CreateAsync(GetUserId(), groupId, dto);
        return new ResultActionResult<SubGroupDetailsDto>(result);
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int groupId, int id, [FromBody] UpdateSubGroupDto dto)
    {
        var result = await subGroupService.UpdateAsync(GetUserId(), groupId, id, dto);
        return new ResultActionResult<SubGroupDetailsDto>(result);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int groupId, int id)
    {
        var result = await subGroupService.DeleteAsync(GetUserId(), groupId, id);
        return new ResultActionResult(result);
    }

    private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier)!;
}
