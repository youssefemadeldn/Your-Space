using System.Security.Claims;
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YourSpace.Repository.Specifications.Paginated;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.CityService;
using YourSpace.Services.Services.CityService.Dtos;
using YourSpace.WebAPI.Helpers;

namespace YourSpace.WebAPI.Controllers;

// Nested under its parent Governorate — every City is scoped to exactly one Governorate (which
// may itself be a shared/global seeded row; only the Governorate row itself is locked).
[ApiController]
[ApiVersion("1.0")]
[Authorize]
[Route("api/v{version:apiVersion}/governorates/{governorateId:int}/cities")]
public class CitiesController(ICityService cityService) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll(int governorateId, [FromQuery] string? search, [FromQuery] PaginationSpecification pagination)
    {
        var result = await cityService.GetAllAsync(GetUserId(), governorateId, search, pagination);
        return new ResultActionResult<PaginatedResultDto<CityProfileDto>>(result);
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetDetails(int governorateId, int id)
    {
        var result = await cityService.GetDetailsAsync(GetUserId(), governorateId, id);
        return new ResultActionResult<CityDetailsDto>(result);
    }

    [HttpPost]
    public async Task<IActionResult> Create(int governorateId, [FromBody] CreateCityDto dto)
    {
        var result = await cityService.CreateAsync(GetUserId(), governorateId, dto);
        return new ResultActionResult<CityDetailsDto>(result);
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int governorateId, int id, [FromBody] UpdateCityDto dto)
    {
        var result = await cityService.UpdateAsync(GetUserId(), governorateId, id, dto);
        return new ResultActionResult<CityDetailsDto>(result);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int governorateId, int id)
    {
        var result = await cityService.DeleteAsync(GetUserId(), governorateId, id);
        return new ResultActionResult(result);
    }

    private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier)!;
}
