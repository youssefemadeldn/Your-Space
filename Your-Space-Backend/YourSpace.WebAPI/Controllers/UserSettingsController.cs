using System.Security.Claims;
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YourSpace.Services.Services.UserSettingsService;
using YourSpace.Services.Services.UserSettingsService.Dtos;
using YourSpace.WebAPI.Helpers;

namespace YourSpace.WebAPI.Controllers;

[ApiController]
[ApiVersion("1.0")]
[Authorize]
[Route("api/v{version:apiVersion}/[controller]")]
public class UserSettingsController(IUserSettingsService userSettingsService) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Get()
    {
        var result = await userSettingsService.GetAsync(GetUserId());
        return new ResultActionResult<UserSettingsDetailsDto>(result);
    }

    [HttpPut]
    public async Task<IActionResult> Update([FromBody] UpdateUserSettingsDto dto)
    {
        var result = await userSettingsService.UpdateAsync(GetUserId(), dto);
        return new ResultActionResult<UserSettingsDetailsDto>(result);
    }

    private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier)!;
}
