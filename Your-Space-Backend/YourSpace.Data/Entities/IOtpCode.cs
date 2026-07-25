namespace YourSpace.Data.Entities;

// Shared shape for EmailConfirmationCode and PasswordResetCode — lets OtpService and its
// specification be written once as generic code against two intentionally separate tables,
// rather than duplicating identical generate/validate logic per entity.
public interface IOtpCode
{
    Guid Id { get; set; }
    string UserId { get; set; }
    string CodeHash { get; set; }
    DateTime ExpiresAt { get; set; }
    DateTime CreatedAt { get; set; }
    int AttemptCount { get; set; }
    DateTime? ConsumedAt { get; set; }
}
