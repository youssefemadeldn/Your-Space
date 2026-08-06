using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using YourSpace.Data.Entities;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications.AuthSpecifications;
using YourSpace.Services.Helper;
using YourSpace.Services.Services.AuthService.Dtos;
using YourSpace.Services.Services.EmailService;
using YourSpace.Services.Services.OtpService;
using YourSpace.Services.Services.TokenService;

namespace YourSpace.Services.Services.AuthService;

public class AuthService(
    UserManager<AppUser> userManager,
    IUnitOfWork unitOfWork,
    ITokenService tokenService,
    IOtpService otpService,
    IEmailSender emailSender,
    IConfiguration configuration,
    ILogger<AuthService> logger) : IAuthService
{
    // Stable, non-localized ErrorCode values a client branches on — never reworded, never changes with
    // Accept-Language (CLAUDE.md Architecture rule 10). Kept as named constants so the two call sites that
    // must share the same code (unknown-email vs. wrong-password, both anti-enumeration) can't drift apart.
    private static class ErrorCodes
    {
        public const string RegisterEmailExists = "Auth.Register.EmailExists";
        public const string InvalidCredentials = "Auth.InvalidCredentials";
        public const string AccountLocked = "Auth.AccountLocked";
        public const string EmailNotConfirmed = "Auth.EmailNotConfirmed";
        public const string RefreshTokenInvalid = "Auth.RefreshToken.Invalid";
        public const string RefreshTokenReused = "Auth.RefreshToken.Reused";
        public const string RefreshTokenRevoked = "Auth.RefreshToken.Revoked";
        public const string RefreshTokenExpired = "Auth.RefreshToken.Expired";
        public const string RefreshTokenNotFound = "Auth.RefreshToken.NotFound";
        public const string ConfirmEmailInvalidRequest = "Auth.ConfirmEmail.InvalidRequest";
        public const string ConfirmEmailFailed = "Auth.ConfirmEmail.Failed";
        public const string ResetPasswordInvalidRequest = "Auth.ResetPassword.InvalidRequest";
        public const string UserNotFound = "Auth.User.NotFound";
        public const string OtpExpired = "Otp.Expired";
        public const string OtpLockedOut = "Otp.LockedOut";
        public const string OtpInvalid = "Otp.Invalid";
    }

    public async Task<ServiceResult<UserProfileDto>> RegisterAsync(RegisterDto dto)
    {
        logger.LogInformation("Registering new user {Email}", dto.Email);

        var existingUser = await userManager.FindByEmailAsync(dto.Email);
        if (existingUser is not null)
        {
            logger.LogWarning("Registration attempted with an already-registered email {Email}", dto.Email);
            return ServiceResult<UserProfileDto>.Conflict("An account with this email already exists.", ErrorCodes.RegisterEmailExists);
        }

        var user = new AppUser
        {
            UserName = dto.Email,
            Email = dto.Email,
            FirstName = dto.FirstName,
            LastName = dto.LastName,
            PhoneNumber = dto.PhoneNumber,
            Gender = dto.Gender
        };

        // CreateAsync (AspNetUsers) and AddToRoleAsync (AspNetUserRoles) are two separate writes —
        // wrapped so a role-assignment failure can never leave a fully-created account with no role.
        await using (var transaction = await unitOfWork.BeginTransactionAsync())
        {
            try
            {
                var createResult = await userManager.CreateAsync(user, dto.Password);
                if (!createResult.Succeeded)
                {
                    logger.LogWarning("Registration failed for {Email}: {Errors}", dto.Email, string.Join(", ", createResult.Errors.Select(e => e.Code)));
                    return ServiceResult<UserProfileDto>.ValidationError(MapIdentityErrors(createResult.Errors), "Registration failed.");
                }

                var roleResult = await userManager.AddToRoleAsync(user, RoleNames.User);
                if (!roleResult.Succeeded)
                {
                    logger.LogError("Failed to assign the default role to new user {Email}: {Errors}", dto.Email, string.Join(", ", roleResult.Errors.Select(e => e.Code)));
                    return ServiceResult<UserProfileDto>.ServerError("Registration could not be completed. Please try again.");
                }

                await unitOfWork.CommitAsync(transaction);
            }
            catch
            {
                await unitOfWork.RollbackAsync(transaction);
                throw;
            }
        }
        // Any return above this point (validation/role failure) leaves the transaction uncommitted —
        // disposing it here rolls it back, so no partially-created account survives either path.

        var otpCode = await otpService.GenerateEmailConfirmationCodeAsync(user.Id);
        await TrySendEmailAsync(
            user.Email!,
            "Confirm your Your Space account",
            $"""
             <p>Welcome to Your Space!</p>
             <p>Use the code below to confirm your account:</p>
             <h2>{otpCode}</h2>
             <p>This code expires in {OtpConstants.ExpiryMinutes} minutes.</p>
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
            return ServiceResult<AuthResponseDto>.Fail("Invalid email or password.", ErrorCodes.InvalidCredentials, 401);
        }

        if (await userManager.IsLockedOutAsync(user))
        {
            logger.LogWarning("Login attempted for a locked-out user {UserId}", user.Id);
            return ServiceResult<AuthResponseDto>.Fail("This account is temporarily locked. Try again later.", ErrorCodes.AccountLocked, 423);
        }

        if (!await userManager.CheckPasswordAsync(user, dto.Password))
        {
            await userManager.AccessFailedAsync(user);
            logger.LogWarning("Invalid password for user {UserId}", user.Id);
            return ServiceResult<AuthResponseDto>.Fail("Invalid email or password.", ErrorCodes.InvalidCredentials, 401);
        }

        if (!await userManager.IsEmailConfirmedAsync(user))
        {
            logger.LogWarning("Login blocked for unconfirmed email, user {UserId}", user.Id);
            return ServiceResult<AuthResponseDto>.Fail("Please confirm your email before logging in.", ErrorCodes.EmailNotConfirmed, 403);
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
            return ServiceResult<AuthResponseDto>.Fail("Invalid refresh token.", ErrorCodes.RefreshTokenInvalid, 401);
        }

        if (stored.RevokedAt is not null)
        {
            // ReplacedByTokenHash only gets set by rotation (below) — a token revoked that way being
            // presented again means a *newer* token already exists downstream, the signature of a
            // stolen/replayed token, not just a stale client. A plain logout-revoked token doesn't
            // carry that signal, so it shouldn't nuke every other session on what could just be a
            // client retry racing a logout.
            if (stored.ReplacedByTokenHash is not null)
            {
                logger.LogWarning("Refresh token reuse detected for user {UserId} — revoking all active sessions", stored.UserId);
                await RevokeAllUserTokensAsync(stored.UserId);
                return ServiceResult<AuthResponseDto>.Fail("This refresh token has already been used. Please log in again.", ErrorCodes.RefreshTokenReused, 401);
            }

            logger.LogWarning("Refresh attempted with an already-revoked token for user {UserId}", stored.UserId);
            return ServiceResult<AuthResponseDto>.Fail("This refresh token has been revoked. Please log in again.", ErrorCodes.RefreshTokenRevoked, 401);
        }

        if (stored.ExpiresAt < DateTime.UtcNow)
        {
            logger.LogWarning("Expired refresh token presented for user {UserId}", stored.UserId);
            return ServiceResult<AuthResponseDto>.Fail("Your session has expired. Please log in again.", ErrorCodes.RefreshTokenExpired, 401);
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
            return ServiceResult.NotFound("Refresh token not found.", ErrorCodes.RefreshTokenNotFound);
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
        var user = await userManager.FindByEmailAsync(dto.Email);
        if (user is null)
        {
            return ServiceResult.Fail("Invalid or expired confirmation code.", ErrorCodes.ConfirmEmailInvalidRequest, 400);
        }

        var transaction = await unitOfWork.BeginTransactionAsync();
        try
        {
            var otpResult = await otpService.ValidateEmailConfirmationCodeAsync(user.Id, dto.Code);
            if (otpResult != OtpValidationResult.Success)
            {
                // ValidateAsync already persisted an attempt-count increment or a lockout for this
                // outcome — that's a real state change worth keeping, so it commits either way.
                await unitOfWork.CommitAsync(transaction);
                logger.LogWarning("Email confirmation failed for user {UserId}: {Result}", user.Id, otpResult);
                return MapOtpFailure(otpResult, "confirmation code");
            }

            var confirmationToken = await userManager.GenerateEmailConfirmationTokenAsync(user);
            var confirmResult = await userManager.ConfirmEmailAsync(user, confirmationToken);
            if (!confirmResult.Succeeded)
            {
                // Not the user's fault — roll back the OTP consumption too, so the code stays usable.
                await unitOfWork.RollbackAsync(transaction);
                logger.LogError("Email confirmation failed for user {UserId} after a valid code: {Errors}", user.Id, string.Join(", ", confirmResult.Errors.Select(e => e.Code)));
                return ServiceResult.Fail("Email confirmation failed. Please try again.", ErrorCodes.ConfirmEmailFailed, 400);
            }

            await unitOfWork.CommitAsync(transaction);
        }
        catch
        {
            await unitOfWork.RollbackAsync(transaction);
            throw;
        }

        logger.LogInformation("Email confirmed for user {UserId}", user.Id);
        return ServiceResult.Ok("Email confirmed successfully. You can now log in.");
    }

    public async Task<ServiceResult> ResendConfirmationEmailAsync(ResendConfirmationEmailDto dto)
    {
        var user = await userManager.FindByEmailAsync(dto.Email);
        if (user is not null && !await userManager.IsEmailConfirmedAsync(user))
        {
            var code = await otpService.GenerateEmailConfirmationCodeAsync(user.Id);
            await TrySendEmailAsync(
                user.Email!,
                "Confirm your Your Space account",
                $"""
                 <p>Your confirmation code is:</p>
                 <h2>{code}</h2>
                 <p>This code expires in {OtpConstants.ExpiryMinutes} minutes.</p>
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
            var code = await otpService.GeneratePasswordResetCodeAsync(user.Id);
            await TrySendEmailAsync(
                user.Email!,
                "Reset your Your Space password",
                $"""
                 <p>Your password reset code is:</p>
                 <h2>{code}</h2>
                 <p>This code expires in {OtpConstants.ExpiryMinutes} minutes.</p>
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
            return ServiceResult.Fail("Invalid or expired reset request.", ErrorCodes.ResetPasswordInvalidRequest, 400);
        }

        var transaction = await unitOfWork.BeginTransactionAsync();
        try
        {
            var otpResult = await otpService.ValidatePasswordResetCodeAsync(user.Id, dto.Code);
            if (otpResult != OtpValidationResult.Success)
            {
                await unitOfWork.CommitAsync(transaction);
                logger.LogWarning("Password reset failed for user {UserId}: {Result}", user.Id, otpResult);
                return MapOtpFailure(otpResult, "reset code");
            }

            var resetToken = await userManager.GeneratePasswordResetTokenAsync(user);
            var resetResult = await userManager.ResetPasswordAsync(user, resetToken, dto.NewPassword);
            if (!resetResult.Succeeded)
            {
                await unitOfWork.RollbackAsync(transaction);
                logger.LogWarning("Password reset failed for user {UserId} after a valid code", user.Id);
                return ServiceResult.ValidationError(MapIdentityErrors(resetResult.Errors), "Password reset failed.");
            }

            await RevokeAllActiveTokensCoreAsync(user.Id);
            await unitOfWork.CommitAsync(transaction);
        }
        catch
        {
            await unitOfWork.RollbackAsync(transaction);
            throw;
        }

        logger.LogInformation("Password reset for user {UserId}", user.Id);
        return ServiceResult.Ok("Password has been reset successfully. Please log in with your new password.");
    }

    public async Task<ServiceResult> ChangePasswordAsync(string userId, ChangePasswordDto dto)
    {
        var user = await userManager.FindByIdAsync(userId);
        if (user is null)
        {
            return ServiceResult.NotFound("User not found.", ErrorCodes.UserNotFound);
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
            return ServiceResult<UserProfileDto>.NotFound("User not found.", ErrorCodes.UserNotFound);
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

    // The fetch-active + mark-revoked + SaveChangesAsync logic, with no transaction handling of its
    // own — callable directly from inside a caller's already-open transaction (ResetPasswordAsync)
    // without hitting UnitOfWork.BeginTransactionAsync's lack of a reentrancy guard.
    private async Task RevokeAllActiveTokensCoreAsync(string userId)
    {
        var repo = unitOfWork.Repository<RefreshToken, Guid>();
        var activeTokens = await repo.ListAllWithSpecAsync(new ActiveRefreshTokensByUserSpecs(userId));
        if (activeTokens.Count == 0)
        {
            return;
        }

        foreach (var token in activeTokens)
        {
            token.RevokedAt = DateTime.UtcNow;
            repo.Update(token);
        }

        await unitOfWork.SaveChangesAsync();
    }

    private async Task RevokeAllUserTokensAsync(string userId)
    {
        var transaction = await unitOfWork.BeginTransactionAsync();
        try
        {
            await RevokeAllActiveTokensCoreAsync(userId);
            await unitOfWork.CommitAsync(transaction);
        }
        catch
        {
            await unitOfWork.RollbackAsync(transaction);
            throw;
        }
    }

    private static ServiceResult MapOtpFailure(OtpValidationResult result, string codeKind) => result switch
    {
        OtpValidationResult.Expired => ServiceResult.Fail($"This {codeKind} has expired. Please request a new one.", ErrorCodes.OtpExpired, 400),
        OtpValidationResult.LockedOut => ServiceResult.Fail("Too many incorrect attempts. Please request a new code.", ErrorCodes.OtpLockedOut, 423),
        _ => ServiceResult.Fail($"Invalid {codeKind}.", ErrorCodes.OtpInvalid, 400)
    };

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
        Gender = user.Gender,
        Roles = roles
    };

    private int GetRefreshTokenExpirationDays() => configuration.GetValue("Jwt:RefreshTokenExpirationDays", 7);

    private static Dictionary<string, string[]> MapIdentityErrors(IEnumerable<IdentityError> errors) =>
        errors.GroupBy(e => e.Code).ToDictionary(g => g.Key, g => g.Select(e => e.Description).ToArray());
}
