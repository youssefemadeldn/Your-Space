namespace YourSpace.Services.Services.OtpService;

public interface IOtpService
{
    Task<string> GenerateEmailConfirmationCodeAsync(string userId);
    Task<OtpValidationResult> ValidateEmailConfirmationCodeAsync(string userId, string code);
    Task<string> GeneratePasswordResetCodeAsync(string userId);
    Task<OtpValidationResult> ValidatePasswordResetCodeAsync(string userId, string code);
}
