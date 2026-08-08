using System.Security.Claims;
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.NeighborhoodService;
using YourSpace.Services.Services.NeighborhoodService.Dtos;
using YourSpace.WebAPI.Helpers;

namespace YourSpace.WebAPI.Controllers;

// Nested under its parent City — every Neighborhood is scoped to exactly one City, and is itself
// the leaf of the location hierarchy (no further child level).
[ApiController]
[ApiVersion("1.0")]
[Authorize]
[Route("api/v{version:apiVersion}/cities/{cityId:int}/neighborhoods")]
public class NeighborhoodsController(INeighborhoodService neighborhoodService) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll(int cityId, [FromQuery] string? search, [FromQuery] PaginationSpecification pagination)
    {
        var result = await neighborhoodService.GetAllAsync(GetUserId(), cityId, search, pagination);
        return new ResultActionResult<PaginatedResultDto<NeighborhoodProfileDto>>(result);
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetDetails(int cityId, int id)
    {
        var result = await neighborhoodService.GetDetailsAsync(GetUserId(), cityId, id);
        return new ResultActionResult<NeighborhoodDetailsDto>(result);
    }

    [HttpPost]
    public async Task<IActionResult> Create(int cityId, [FromBody] CreateNeighborhoodDto dto)
    {
        var result = await neighborhoodService.CreateAsync(GetUserId(), cityId, dto);
        return new ResultActionResult<NeighborhoodDetailsDto>(result);
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int cityId, int id, [FromBody] UpdateNeighborhoodDto dto)
    {
        var result = await neighborhoodService.UpdateAsync(GetUserId(), cityId, id, dto);
        return new ResultActionResult<NeighborhoodDetailsDto>(result);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int cityId, int id)
    {
        var result = await neighborhoodService.DeleteAsync(GetUserId(), cityId, id);
        return new ResultActionResult(result);
    }

    private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier)!;
}
