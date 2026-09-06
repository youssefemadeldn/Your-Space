using System.Security.Claims;
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.GovernorateService;
using YourSpace.Services.Services.GovernorateService.Dtos;
using YourSpace.WebAPI.Helpers;

namespace YourSpace.WebAPI.Controllers;

// Not nested — Governorate is level 1 of the location hierarchy, with no parent of its own.
// GetAllAsync returns shared/global (seeded) rows plus the caller's own custom rows.
[ApiController]
[ApiVersion("1.0")]
[Authorize]
[Route("api/v{version:apiVersion}/[controller]")]
public class GovernoratesController(IGovernorateService governorateService) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] string? search, [FromQuery] PaginationSpecification pagination)
    {
        var result = await governorateService.GetAllAsync(GetUserId(), search, pagination);
        return new ResultActionResult<PaginatedResultDto<GovernorateProfileDto>>(result);
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetDetails(int id)
    {
        var result = await governorateService.GetDetailsAsync(GetUserId(), id);
        return new ResultActionResult<GovernorateDetailsDto>(result);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateGovernorateDto dto)
    {
        var result = await governorateService.CreateAsync(GetUserId(), dto);
        return new ResultActionResult<GovernorateDetailsDto>(result);
    }

    [HttpPut]
    public async Task<IActionResult> Update([FromBody] UpdateGovernorateDto dto)
    {
        var result = await governorateService.UpdateAsync(GetUserId(), dto);
        return new ResultActionResult<GovernorateDetailsDto>(result);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var result = await governorateService.DeleteAsync(GetUserId(), id);
        return new ResultActionResult(result);
    }

    private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier)!;
}
