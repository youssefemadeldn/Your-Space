using YourSpace.Services.Helper;
using YourSpace.Services.Services.AuthService.Dtos;

namespace YourSpace.Services.Services.AuthService;

public interface IAuthService
{
    Task<ServiceResult<UserProfileDto>> RegisterAsync(RegisterDto dto);
    Task<ServiceResult<AuthResponseDto>> LoginAsync(LoginDto dto, string? ipAddress);
    Task<ServiceResult<AuthResponseDto>> RefreshTokenAsync(string refreshToken, string? ipAddress);
    Task<ServiceResult> RevokeTokenAsync(string refreshToken, string? ipAddress);
    Task<ServiceResult> ConfirmEmailAsync(ConfirmEmailDto dto);
    Task<ServiceResult> ResendConfirmationEmailAsync(ResendConfirmationEmailDto dto);
    Task<ServiceResult> ForgotPasswordAsync(ForgotPasswordDto dto);
    Task<ServiceResult> ResetPasswordAsync(ResetPasswordDto dto);
    Task<ServiceResult> ChangePasswordAsync(string userId, ChangePasswordDto dto);
    Task<ServiceResult<UserProfileDto>> GetProfileAsync(string userId);
}
