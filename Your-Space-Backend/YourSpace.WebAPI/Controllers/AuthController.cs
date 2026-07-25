using System.Security.Claims;
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using YourSpace.Services.Services.AuthService;
using YourSpace.Services.Services.AuthService.Dtos;
using YourSpace.WebAPI.Extensions;
using YourSpace.WebAPI.Helpers;

namespace YourSpace.WebAPI.Controllers;

[ApiController]
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/[controller]")]
public class AuthController(IAuthService authService) : ControllerBase
{
    // Public — anyone can create an account.
    [HttpPost("register")]
    [EnableRateLimiting(RateLimitingExtension.AuthPolicy)]
    public async Task<IActionResult> Register([FromBody] RegisterDto dto)
    {
        var result = await authService.RegisterAsync(dto);
        return new ResultActionResult<UserProfileDto>(result);
    }

    // Public — this is how a client authenticates in the first place.
    [HttpPost("login")]
    [EnableRateLimiting(RateLimitingExtension.AuthPolicy)]
    public async Task<IActionResult> Login([FromBody] LoginDto dto)
    {
        var result = await authService.LoginAsync(dto, GetClientIp());
        return new ResultActionResult<AuthResponseDto>(result);
    }

    // Public — the refresh token itself is the credential being presented.
    [HttpPost("refresh-token")]
    [EnableRateLimiting(RateLimitingExtension.AuthPolicy)]
    public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequestDto dto)
    {
        var result = await authService.RefreshTokenAsync(dto.RefreshToken, GetClientIp());
        return new ResultActionResult<AuthResponseDto>(result);
    }

    // Public — logout only needs the refresh token being revoked, not an active access token.
    [HttpPost("revoke-token")]
    public async Task<IActionResult> RevokeToken([FromBody] RevokeTokenDto dto)
    {
        var result = await authService.RevokeTokenAsync(dto.RefreshToken, GetClientIp());
        return new ResultActionResult(result);
    }

    // Public — reached via the link/token sent to the user's email, before they can log in.
    [HttpGet("confirm-email")]
    public async Task<IActionResult> ConfirmEmail([FromQuery] ConfirmEmailDto dto)
    {
        var result = await authService.ConfirmEmailAsync(dto);
        return new ResultActionResult(result);
    }

    // Public — the response is deliberately identical whether or not the email exists.
    [HttpPost("resend-confirmation-email")]
    [EnableRateLimiting(RateLimitingExtension.AuthPolicy)]
    public async Task<IActionResult> ResendConfirmationEmail([FromBody] ResendConfirmationEmailDto dto)
    {
        var result = await authService.ResendConfirmationEmailAsync(dto);
        return new ResultActionResult(result);
    }

    // Public — the response is deliberately identical whether or not the email exists.
    [HttpPost("forgot-password")]
    [EnableRateLimiting(RateLimitingExtension.AuthPolicy)]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordDto dto)
    {
        var result = await authService.ForgotPasswordAsync(dto);
        return new ResultActionResult(result);
    }

    // Public — reached via the reset token sent to the user's email.
    [HttpPost("reset-password")]
    [EnableRateLimiting(RateLimitingExtension.AuthPolicy)]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordDto dto)
    {
        var result = await authService.ResetPasswordAsync(dto);
        return new ResultActionResult(result);
    }

    [HttpPost("change-password")]
    [Authorize]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordDto dto)
    {
        var result = await authService.ChangePasswordAsync(GetUserId(), dto);
        return new ResultActionResult(result);
    }

    [HttpGet("me")]
    [Authorize]
    public async Task<IActionResult> GetProfile()
    {
        var result = await authService.GetProfileAsync(GetUserId());
        return new ResultActionResult<UserProfileDto>(result);
    }

    // Safe: every action calling this is behind [Authorize], and TokenService.GenerateAccessToken
    // always emits a NameIdentifier claim, so it's never actually missing here.
    private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier)!;

    private string? GetClientIp() => HttpContext.Connection.RemoteIpAddress?.ToString();
}
