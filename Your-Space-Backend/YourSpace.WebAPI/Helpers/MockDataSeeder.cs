using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using YourSpace.Data.Contexts;
using YourSpace.Data.Entities;
using YourSpace.Services.Services.AuthService;
using YourSpace.Services.Services.OtpService;

namespace YourSpace.WebAPI.Helpers;

// Development-only sample data — never runs outside app.Environment.IsDevelopment() (CLAUDE.md
// "Development Data Seeding"). Distinct from IdentitySeeder, which bootstraps real, production-needed
// data (roles, the first SuperAdmin) and therefore runs in every environment.
public static class MockDataSeeder
{
    private const string ActiveUserEmail = "seed.active@yourspace.dev";
    private const string LockedUserEmail = "seed.locked@yourspace.dev";
    private const string SeedUserPassword = "Seed!Pass123";

    public static async Task SeedAsync(YourSpaceDbContext context, UserManager<AppUser> userManager)
    {
        var (activeUserId, lockedUserId) = await SeedDevUsersAsync(userManager);

        await SeedRefreshTokensAsync(context, activeUserId, lockedUserId);
        await SeedEmailConfirmationCodesAsync(context, activeUserId, lockedUserId);
        await SeedPasswordResetCodesAsync(context, activeUserId, lockedUserId);
    }

    // Dedicated, disposable local-dev fixture accounts — distinct from IdentitySeeder's real SuperAdmin
    // bootstrap — that exist only to give RefreshToken/EmailConfirmationCode/PasswordResetCode sample
    // rows a valid UserId to attach to. Created via UserManager (not a raw context insert) so password
    // hashing and the security stamp are set up the same way a real registration would.
    private static async Task<(string ActiveUserId, string LockedUserId)> SeedDevUsersAsync(UserManager<AppUser> userManager)
    {
        var activeUser = await GetOrCreateSeedUserAsync(userManager, ActiveUserEmail, "Seed", "Active");
        var lockedUser = await GetOrCreateSeedUserAsync(userManager, LockedUserEmail, "Seed", "Locked");
        return (activeUser.Id, lockedUser.Id);
    }

    private static async Task<AppUser> GetOrCreateSeedUserAsync(UserManager<AppUser> userManager, string email, string firstName, string lastName)
    {
        var existing = await userManager.FindByEmailAsync(email);
        if (existing is not null)
        {
            return existing;
        }

        var user = new AppUser
        {
            UserName = email,
            Email = email,
            FirstName = firstName,
            LastName = lastName,
            EmailConfirmed = true
        };

        var createResult = await userManager.CreateAsync(user, SeedUserPassword);
        if (!createResult.Succeeded)
        {
            throw new InvalidOperationException(
                $"Failed to seed dev user {email}: {string.Join(", ", createResult.Errors.Select(e => e.Description))}");
        }

        await userManager.AddToRoleAsync(user, RoleNames.User);
        return user;
    }

    private static async Task SeedRefreshTokensAsync(YourSpaceDbContext context, string activeUserId, string lockedUserId)
    {
        if (await context.RefreshTokens.AnyAsync())
        {
            return;
        }

        await context.RefreshTokens.AddRangeAsync(
            new RefreshToken // normal case — active, unexpired session
            {
                Id = Guid.NewGuid(),
                UserId = activeUserId,
                TokenHash = HashSeedValue("seed-refresh-active"),
                ExpiresAt = DateTime.UtcNow.AddDays(7),
                CreatedAt = DateTime.UtcNow
            },
            new RefreshToken // edge case — expired
            {
                Id = Guid.NewGuid(),
                UserId = activeUserId,
                TokenHash = HashSeedValue("seed-refresh-expired"),
                ExpiresAt = DateTime.UtcNow.AddDays(-1),
                CreatedAt = DateTime.UtcNow.AddDays(-8)
            },
            new RefreshToken // edge case — revoked via a completed rotation
            {
                Id = Guid.NewGuid(),
                UserId = lockedUserId,
                TokenHash = HashSeedValue("seed-refresh-rotated-out"),
                ExpiresAt = DateTime.UtcNow.AddDays(6),
                CreatedAt = DateTime.UtcNow.AddDays(-1),
                RevokedAt = DateTime.UtcNow.AddHours(-2),
                ReplacedByTokenHash = HashSeedValue("seed-refresh-post-rotation")
            });

        await context.SaveChangesAsync();
    }

    private static async Task SeedEmailConfirmationCodesAsync(YourSpaceDbContext context, string activeUserId, string lockedUserId)
    {
        if (await context.EmailConfirmationCodes.AnyAsync())
        {
            return;
        }

        var now = DateTime.UtcNow;
        await context.EmailConfirmationCodes.AddRangeAsync(
            new EmailConfirmationCode // normal case — still valid, unconsumed
            {
                Id = Guid.NewGuid(),
                UserId = activeUserId,
                CodeHash = HashSeedValue("111111"),
                CreatedAt = now,
                ExpiresAt = now.AddMinutes(OtpConstants.ExpiryMinutes),
                AttemptCount = 0
            },
            new EmailConfirmationCode // edge case — already consumed
            {
                Id = Guid.NewGuid(),
                UserId = activeUserId,
                CodeHash = HashSeedValue("222222"),
                CreatedAt = now.AddMinutes(-30),
                ExpiresAt = now.AddMinutes(-20),
                AttemptCount = 1,
                ConsumedAt = now.AddMinutes(-25)
            },
            new EmailConfirmationCode // edge case — locked out after max failed attempts
            {
                Id = Guid.NewGuid(),
                UserId = lockedUserId,
                CodeHash = HashSeedValue("333333"),
                CreatedAt = now.AddMinutes(-5),
                ExpiresAt = now.AddMinutes(OtpConstants.ExpiryMinutes - 5),
                AttemptCount = OtpConstants.MaxAttempts,
                ConsumedAt = now.AddMinutes(-1)
            });

        await context.SaveChangesAsync();
    }

    private static async Task SeedPasswordResetCodesAsync(YourSpaceDbContext context, string activeUserId, string lockedUserId)
    {
        if (await context.PasswordResetCodes.AnyAsync())
        {
            return;
        }

        var now = DateTime.UtcNow;
        await context.PasswordResetCodes.AddRangeAsync(
            new PasswordResetCode // normal case — still valid, unconsumed
            {
                Id = Guid.NewGuid(),
                UserId = activeUserId,
                CodeHash = HashSeedValue("444444"),
                CreatedAt = now,
                ExpiresAt = now.AddMinutes(OtpConstants.ExpiryMinutes),
                AttemptCount = 0
            },
            new PasswordResetCode // edge case — already consumed
            {
                Id = Guid.NewGuid(),
                UserId = activeUserId,
                CodeHash = HashSeedValue("555555"),
                CreatedAt = now.AddMinutes(-30),
                ExpiresAt = now.AddMinutes(-20),
                AttemptCount = 1,
                ConsumedAt = now.AddMinutes(-25)
            },
            new PasswordResetCode // edge case — locked out after max failed attempts
            {
                Id = Guid.NewGuid(),
                UserId = lockedUserId,
                CodeHash = HashSeedValue("666666"),
                CreatedAt = now.AddMinutes(-5),
                ExpiresAt = now.AddMinutes(OtpConstants.ExpiryMinutes - 5),
                AttemptCount = OtpConstants.MaxAttempts,
                ConsumedAt = now.AddMinutes(-1)
            });

        await context.SaveChangesAsync();
    }

    // Mirrors TokenService.HashToken's SHA-256 hex algorithm — these seed rows are never presented by a
    // real client, but using the same hash shape keeps them realistic rather than placeholder text.
    private static string HashSeedValue(string value) =>
        Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(value)));
}
