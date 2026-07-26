using System.Security.Claims;
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.GroupService;
using YourSpace.Services.Services.GroupService.Dtos;
using YourSpace.WebAPI.Helpers;

namespace YourSpace.WebAPI.Controllers;

// Every Group is private to its owner — every action here requires an authenticated caller.
[ApiController]
[ApiVersion("1.0")]
[Authorize]
[Route("api/v{version:apiVersion}/[controller]")]
public class GroupsController(IGroupService groupService) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] string? search, [FromQuery] PaginationSpecification pagination)
    {
        var result = await groupService.GetAllAsync(GetUserId(), search, pagination);
        return new ResultActionResult<PaginatedResultDto<GroupProfileDto>>(result);
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetDetails(int id)
    {
        var result = await groupService.GetDetailsAsync(GetUserId(), id);
        return new ResultActionResult<GroupDetailsDto>(result);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateGroupDto dto)
    {
        var result = await groupService.CreateAsync(GetUserId(), dto);
        return new ResultActionResult<GroupDetailsDto>(result);
    }

    [HttpPut]
    public async Task<IActionResult> Update([FromBody] UpdateGroupDto dto)
    {
        var result = await groupService.UpdateAsync(GetUserId(), dto);
        return new ResultActionResult<GroupDetailsDto>(result);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var result = await groupService.DeleteAsync(GetUserId(), id);
        return new ResultActionResult(result);
    }

    private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier)!;
}
