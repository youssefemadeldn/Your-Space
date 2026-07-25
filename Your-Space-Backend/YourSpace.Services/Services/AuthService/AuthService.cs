using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications.AuthSpecifications;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.AuthService.Dtos;
using YourSpace.Services.Services.EmailService;
using YourSpace.Services.Services.TokenService;

namespace YourSpace.Services.Services.AuthService;

public class AuthService(
    UserManager<AppUser> userManager,
    IUnitOfWork unitOfWork,
    ITokenService tokenService,
    IEmailSender emailSender,
    IConfiguration configuration,
    ILogger<AuthService> logger) : IAuthService
{
    public async Task<ServiceResult<UserProfileDto>> RegisterAsync(RegisterDto dto)
    {
        logger.LogInformation("Registering new user {Email}", dto.Email);

        var existingUser = await userManager.FindByEmailAsync(dto.Email);
        if (existingUser is not null)
        {
            logger.LogWarning("Registration attempted with an already-registered email {Email}", dto.Email);
            return ServiceResult<UserProfileDto>.Conflict("An account with this email already exists.");
        }

        var user = new AppUser
        {
            UserName = dto.Email,
            Email = dto.Email,
            FirstName = dto.FirstName,
            LastName = dto.LastName,
            PhoneNumber = dto.PhoneNumber
        };

        var createResult = await userManager.CreateAsync(user, dto.Password);
        if (!createResult.Succeeded)
        {
            logger.LogWarning("Registration failed for {Email}: {Errors}", dto.Email, string.Join(", ", createResult.Errors.Select(e => e.Code)));
            return ServiceResult<UserProfileDto>.ValidationError(MapIdentityErrors(createResult.Errors), "Registration failed.");
        }

        await userManager.AddToRoleAsync(user, RoleNames.User);

        var confirmationToken = await userManager.GenerateEmailConfirmationTokenAsync(user);
        await TrySendEmailAsync(
            user.Email!,
            "Confirm your Your Space account",
            $"""
             <p>Welcome to Your Space!</p>
             <p>Use the details below to confirm your account:</p>
             <p>User Id: {user.Id}</p>
             <p>Confirmation token: {confirmationToken}</p>
             """,
            "confirmation");

        var profile = await BuildProfileAsync(user);
        return ServiceResult<UserProfileDto>.Created(profile, "Registration successful. Please check your email to confirm your account.");
    }

    public async Task<ServiceResult<AuthResponseDto>> LoginAsync(LoginDto dto, string? ipAddress)
    {
        var user = await userManager.FindByEmailAsync(dto.Email);
        if (user is null)
        {
            logger.LogWarning("Login attempted for an unknown email {Email}", dto.Email);
            return ServiceResult<AuthResponseDto>.Fail("Invalid email or password.", 401);
        }

        if (await userManager.IsLockedOutAsync(user))
        {
            logger.LogWarning("Login attempted for a locked-out user {UserId}", user.Id);
            return ServiceResult<AuthResponseDto>.Fail("This account is temporarily locked. Try again later.", 423);
        }

        if (!await userManager.CheckPasswordAsync(user, dto.Password))
        {
            await userManager.AccessFailedAsync(user);
            logger.LogWarning("Invalid password for user {UserId}", user.Id);
            return ServiceResult<AuthResponseDto>.Fail("Invalid email or password.", 401);
        }

        if (!await userManager.IsEmailConfirmedAsync(user))
        {
            logger.LogWarning("Login blocked for unconfirmed email, user {UserId}", user.Id);
            return ServiceResult<AuthResponseDto>.Fail("Please confirm your email before logging in.", 403);
        }

        await userManager.ResetAccessFailedCountAsync(user);

        var roles = await userManager.GetRolesAsync(user);
        var authResponse = await IssueTokensAsync(user, roles, ipAddress);

        logger.LogInformation("User {UserId} logged in", user.Id);
        return ServiceResult<AuthResponseDto>.Ok(authResponse, "Login successful.");
    }

    public async Task<ServiceResult<AuthResponseDto>> RefreshTokenAsync(string refreshToken, string? ipAddress)
    {
        var repo = unitOfWork.Repository<RefreshToken, Guid>();
        var tokenHash = tokenService.HashToken(refreshToken);
        var stored = await repo.GetByIdWithSpecAsync(new RefreshTokenWithSpecs(tokenHash));

        if (stored is null)
        {
            logger.LogWarning("Refresh attempted with an unknown token");
            return ServiceResult<AuthResponseDto>.Fail("Invalid refresh token.", 401);
        }

        if (stored.RevokedAt is not null)
        {
            logger.LogWarning("Refresh token reuse detected for user {UserId} — revoking all active sessions", stored.UserId);
            await RevokeAllUserTokensAsync(stored.UserId);
            return ServiceResult<AuthResponseDto>.Fail("This refresh token has already been used. Please log in again.", 401);
        }

        if (stored.ExpiresAt < DateTime.UtcNow)
        {
            logger.LogWarning("Expired refresh token presented for user {UserId}", stored.UserId);
            return ServiceResult<AuthResponseDto>.Fail("Your session has expired. Please log in again.", 401);
        }

        var roles = await userManager.GetRolesAsync(stored.User);
        var (accessToken, accessExpiresAt) = tokenService.GenerateAccessToken(stored.User, roles);
        var newRawToken = tokenService.GenerateRefreshToken();
        var newHash = tokenService.HashToken(newRawToken);

        var transaction = await unitOfWork.BeginTransactionAsync();
        try
        {
            stored.RevokedAt = DateTime.UtcNow;
            stored.RevokedByIp = ipAddress;
            stored.ReplacedByTokenHash = newHash;
            repo.Update(stored);

            await repo.AddAsync(new RefreshToken
            {
                Id = Guid.NewGuid(),
                UserId = stored.UserId,
                TokenHash = newHash,
                ExpiresAt = DateTime.UtcNow.AddDays(GetRefreshTokenExpirationDays()),
                CreatedAt = DateTime.UtcNow,
                CreatedByIp = ipAddress
            });

            await unitOfWork.SaveChangesAsync();
            await unitOfWork.CommitAsync(transaction);
        }
        catch
        {
            await unitOfWork.RollbackAsync(transaction);
            throw;
        }

        var profile = BuildProfile(stored.User, roles);
        return ServiceResult<AuthResponseDto>.Ok(new AuthResponseDto
        {
            AccessToken = accessToken,
            AccessTokenExpiresAt = accessExpiresAt,
            RefreshToken = newRawToken,
            User = profile
        }, "Token refreshed successfully.");
    }

    public async Task<ServiceResult> RevokeTokenAsync(string refreshToken, string? ipAddress)
    {
        var repo = unitOfWork.Repository<RefreshToken, Guid>();
        var tokenHash = tokenService.HashToken(refreshToken);
        var stored = await repo.GetByIdWithSpecAsync(new RefreshTokenWithSpecs(tokenHash));

        if (stored is null)
        {
            return ServiceResult.NotFound("Refresh token not found.");
        }

        if (stored.RevokedAt is null)
        {
            stored.RevokedAt = DateTime.UtcNow;
            stored.RevokedByIp = ipAddress;
            repo.Update(stored);
            await unitOfWork.SaveChangesAsync();
        }

        logger.LogInformation("User {UserId} logged out", stored.UserId);
        return ServiceResult.Ok("Logged out successfully.");
    }

    public async Task<ServiceResult> ConfirmEmailAsync(ConfirmEmailDto dto)
    {
        var user = await userManager.FindByIdAsync(dto.UserId);
        if (user is null)
        {
            return ServiceResult.Fail("Invalid confirmation link.", 400);
        }

        var result = await userManager.ConfirmEmailAsync(user, dto.Token);
        if (!result.Succeeded)
        {
            logger.LogWarning("Email confirmation failed for user {UserId}", user.Id);
            return ServiceResult.Fail("Invalid or expired confirmation link.", 400);
        }

        logger.LogInformation("Email confirmed for user {UserId}", user.Id);
        return ServiceResult.Ok("Email confirmed successfully. You can now log in.");
    }

    public async Task<ServiceResult> ResendConfirmationEmailAsync(ResendConfirmationEmailDto dto)
    {
        var user = await userManager.FindByEmailAsync(dto.Email);
        if (user is not null && !await userManager.IsEmailConfirmedAsync(user))
        {
            var token = await userManager.GenerateEmailConfirmationTokenAsync(user);
            await TrySendEmailAsync(
                user.Email!,
                "Confirm your Your Space account",
                $"""
                 <p>User Id: {user.Id}</p>
                 <p>Confirmation token: {token}</p>
                 """,
                "confirmation");
        }

        return ServiceResult.Ok("If an account with that email exists and isn't confirmed yet, a confirmation email has been sent.");
    }

    public async Task<ServiceResult> ForgotPasswordAsync(ForgotPasswordDto dto)
    {
        var user = await userManager.FindByEmailAsync(dto.Email);
        if (user is not null)
        {
            var token = await userManager.GeneratePasswordResetTokenAsync(user);
            await TrySendEmailAsync(
                user.Email!,
                "Reset your Your Space password",
                $"""
                 <p>Email: {user.Email}</p>
                 <p>Reset token: {token}</p>
                 """,
                "password reset");
        }

        return ServiceResult.Ok("If an account with that email exists, a password reset email has been sent.");
    }

    public async Task<ServiceResult> ResetPasswordAsync(ResetPasswordDto dto)
    {
        var user = await userManager.FindByEmailAsync(dto.Email);
        if (user is null)
        {
            return ServiceResult.Fail("Invalid or expired reset request.", 400);
        }

        var result = await userManager.ResetPasswordAsync(user, dto.Token, dto.NewPassword);
        if (!result.Succeeded)
        {
            logger.LogWarning("Password reset failed for user {UserId}", user.Id);
            return ServiceResult.ValidationError(MapIdentityErrors(result.Errors), "Password reset failed.");
        }

        await RevokeAllUserTokensAsync(user.Id);
        logger.LogInformation("Password reset for user {UserId}", user.Id);
        return ServiceResult.Ok("Password has been reset successfully. Please log in with your new password.");
    }

    public async Task<ServiceResult> ChangePasswordAsync(string userId, ChangePasswordDto dto)
    {
        var user = await userManager.FindByIdAsync(userId);
        if (user is null)
        {
            return ServiceResult.NotFound("User not found.");
        }

        var result = await userManager.ChangePasswordAsync(user, dto.CurrentPassword, dto.NewPassword);
        if (!result.Succeeded)
        {
            logger.LogWarning("Password change failed for user {UserId}", user.Id);
            return ServiceResult.ValidationError(MapIdentityErrors(result.Errors), "Password change failed.");
        }

        await RevokeAllUserTokensAsync(user.Id);
        logger.LogInformation("Password changed for user {UserId}", user.Id);
        return ServiceResult.Ok("Password changed successfully.");
    }

    public async Task<ServiceResult<UserProfileDto>> GetProfileAsync(string userId)
    {
        var user = await userManager.FindByIdAsync(userId);
        if (user is null)
        {
            return ServiceResult<UserProfileDto>.NotFound("User not found.");
        }

        return ServiceResult<UserProfileDto>.Ok(await BuildProfileAsync(user));
    }

    private async Task<AuthResponseDto> IssueTokensAsync(AppUser user, IList<string> roles, string? ipAddress)
    {
        var (accessToken, accessExpiresAt) = tokenService.GenerateAccessToken(user, roles);
        var rawRefreshToken = tokenService.GenerateRefreshToken();

        var repo = unitOfWork.Repository<RefreshToken, Guid>();
        await repo.AddAsync(new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            TokenHash = tokenService.HashToken(rawRefreshToken),
            ExpiresAt = DateTime.UtcNow.AddDays(GetRefreshTokenExpirationDays()),
            CreatedAt = DateTime.UtcNow,
            CreatedByIp = ipAddress
        });
        await unitOfWork.SaveChangesAsync();

        return new AuthResponseDto
        {
            AccessToken = accessToken,
            AccessTokenExpiresAt = accessExpiresAt,
            RefreshToken = rawRefreshToken,
            User = BuildProfile(user, roles)
        };
    }

    private async Task RevokeAllUserTokensAsync(string userId)
    {
        var repo = unitOfWork.Repository<RefreshToken, Guid>();
        var activeTokens = await repo.ListAllWithSpecAsync(new ActiveRefreshTokensByUserSpecs(userId));
        if (activeTokens.Count == 0)
        {
            return;
        }

        var transaction = await unitOfWork.BeginTransactionAsync();
        try
        {
            foreach (var token in activeTokens)
            {
                token.RevokedAt = DateTime.UtcNow;
                repo.Update(token);
            }

            await unitOfWork.SaveChangesAsync();
            await unitOfWork.CommitAsync(transaction);
        }
        catch
        {
            await unitOfWork.RollbackAsync(transaction);
            throw;
        }
    }

    private async Task TrySendEmailAsync(string toEmail, string subject, string htmlBody, string emailKind)
    {
        // Best-effort side effect: the primary action (registration, password-reset request, ...)
        // already succeeded and isn't rolled back if delivery fails — the user can retry via the
        // resend/forgot-password endpoints, so a transient SMTP failure shouldn't surface as a 500.
        try
        {
            await emailSender.SendEmailAsync(toEmail, subject, htmlBody);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to send {EmailKind} email to {ToEmail}", emailKind, toEmail);
        }
    }

    private async Task<UserProfileDto> BuildProfileAsync(AppUser user)
    {
        var roles = await userManager.GetRolesAsync(user);
        return BuildProfile(user, roles);
    }

    private static UserProfileDto BuildProfile(AppUser user, IList<string> roles) => new()
    {
        Id = user.Id,
        Email = user.Email!,
        FirstName = user.FirstName,
        LastName = user.LastName,
        PhoneNumber = user.PhoneNumber,
        Roles = roles
    };

    private int GetRefreshTokenExpirationDays() => configuration.GetValue("Jwt:RefreshTokenExpirationDays", 7);

    private static Dictionary<string, string[]> MapIdentityErrors(IEnumerable<IdentityError> errors) =>
        errors.GroupBy(e => e.Code).ToDictionary(g => g.Key, g => g.Select(e => e.Description).ToArray());
}
