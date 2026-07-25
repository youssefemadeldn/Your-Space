namespace YourSpace.Services.Services.OtpService;

public enum OtpValidationResult
{
    Success,
    NotFound,
    Expired,
    Invalid,
    LockedOut
}
