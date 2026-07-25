namespace YourSpace.Data.Entities;

public class PasswordResetCode : IOtpCode
{
    public Guid Id { get; set; }
    public required string UserId { get; set; }
    public required string CodeHash { get; set; }
    public DateTime ExpiresAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public int AttemptCount { get; set; }
    public DateTime? ConsumedAt { get; set; }

    public AppUser User { get; set; } = null!;
}
