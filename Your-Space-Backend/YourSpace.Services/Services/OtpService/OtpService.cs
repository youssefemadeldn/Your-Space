using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Logging;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications.AuthSpecifications;
using YourSpace.Services.Services.TokenService;

namespace YourSpace.Services.Services.OtpService;

public class OtpService(
    IUnitOfWork unitOfWork,
    ITokenService tokenService,
    ILogger<OtpService> logger) : IOtpService
{
    public Task<string> GenerateEmailConfirmationCodeAsync(string userId)
        => GenerateAsync(userId, (id, hash, createdAt, expiresAt) => new EmailConfirmationCode
        {
            Id = Guid.NewGuid(),
            UserId = id,
            CodeHash = hash,
            CreatedAt = createdAt,
            ExpiresAt = expiresAt,
            AttemptCount = 0
        });

    public Task<OtpValidationResult> ValidateEmailConfirmationCodeAsync(string userId, string code)
        => ValidateAsync<EmailConfirmationCode>(userId, code);

    public Task<string> GeneratePasswordResetCodeAsync(string userId)
        => GenerateAsync(userId, (id, hash, createdAt, expiresAt) => new PasswordResetCode
        {
            Id = Guid.NewGuid(),
            UserId = id,
            CodeHash = hash,
            CreatedAt = createdAt,
            ExpiresAt = expiresAt,
            AttemptCount = 0
        });

    public Task<OtpValidationResult> ValidatePasswordResetCodeAsync(string userId, string code)
        => ValidateAsync<PasswordResetCode>(userId, code);

    // TEntity can't carry a `new()` constraint here — both entities declare `required` members
    // (matching RefreshToken's convention), which the compiler can't verify through a generic `new()`
    // call. The caller supplies a factory instead, keeping this method's core logic generic anyway.
    private async Task<string> GenerateAsync<TEntity>(string userId, Func<string, string, DateTime, DateTime, TEntity> factory)
        where TEntity : class, IOtpCode
    {
        var repo = unitOfWork.Repository<TEntity, Guid>();
        var activeCodes = await repo.ListAllWithSpecAsync(new ActiveOtpCodeByUserSpecs<TEntity>(userId));

        var rawCode = tokenService.GenerateOtpCode(OtpConstants.CodeLength);
        var codeHash = tokenService.HashToken(rawCode);
        var createdAt = DateTime.UtcNow;
        var expiresAt = createdAt.AddMinutes(OtpConstants.ExpiryMinutes);

        var transaction = await unitOfWork.BeginTransactionAsync();
        try
        {
            foreach (var stale in activeCodes)
            {
                stale.ConsumedAt = DateTime.UtcNow;
                repo.Update(stale);
            }

            await repo.AddAsync(factory(userId, codeHash, createdAt, expiresAt));

            await unitOfWork.SaveChangesAsync();
            await unitOfWork.CommitAsync(transaction);
        }
        catch
        {
            await unitOfWork.RollbackAsync(transaction);
            throw;
        }

        logger.LogInformation("Generated {OtpType} for user {UserId}", typeof(TEntity).Name, userId);
        return rawCode;
    }

    private async Task<OtpValidationResult> ValidateAsync<TEntity>(string userId, string code) where TEntity : class, IOtpCode
    {
        var repo = unitOfWork.Repository<TEntity, Guid>();
        var stored = await repo.GetByIdWithSpecAsync(new ActiveOtpCodeByUserSpecs<TEntity>(userId));

        if (stored is null)
        {
            logger.LogWarning("{OtpType} validation attempted with no active code for user {UserId}", typeof(TEntity).Name, userId);
            return OtpValidationResult.NotFound;
        }

        if (stored.ExpiresAt < DateTime.UtcNow)
        {
            logger.LogWarning("Expired {OtpType} presented for user {UserId}", typeof(TEntity).Name, userId);
            return OtpValidationResult.Expired;
        }

        // Rows are found by (UserId, ConsumedAt == null), never by hash — a 6-digit code's keyspace is far
        // too small for its hash to serve as a lookup key the way RefreshToken.TokenHash does. The hash
        // comparison only ever happens here, after narrowing to this one user's one active code, using a
        // constant-time compare (safe because both sides are always a 64-char SHA-256 hex string).
        var presentedHash = tokenService.HashToken(code);
        var isMatch = CryptographicOperations.FixedTimeEquals(
            Encoding.UTF8.GetBytes(presentedHash),
            Encoding.UTF8.GetBytes(stored.CodeHash));

        if (!isMatch)
        {
            stored.AttemptCount++;
            if (stored.AttemptCount >= OtpConstants.MaxAttempts)
            {
                stored.ConsumedAt = DateTime.UtcNow;
                repo.Update(stored);
                await unitOfWork.SaveChangesAsync();
                logger.LogWarning("{OtpType} locked out for user {UserId} after {Attempts} failed attempts", typeof(TEntity).Name, userId, stored.AttemptCount);
                return OtpValidationResult.LockedOut;
            }

            repo.Update(stored);
            await unitOfWork.SaveChangesAsync();
            logger.LogWarning("Incorrect {OtpType} presented for user {UserId}, attempt {Attempt}", typeof(TEntity).Name, userId, stored.AttemptCount);
            return OtpValidationResult.Invalid;
        }

        stored.ConsumedAt = DateTime.UtcNow;
        repo.Update(stored);
        await unitOfWork.SaveChangesAsync();
        logger.LogInformation("{OtpType} validated for user {UserId}", typeof(TEntity).Name, userId);
        return OtpValidationResult.Success;
    }
}
