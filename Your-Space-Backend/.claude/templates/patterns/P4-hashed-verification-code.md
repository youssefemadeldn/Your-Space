---
name: P4-hashed-verification-code
governed-by: CLAUDE.md Architecture rule 7 · dotnet_feature_prompt.md Rule 3 & §4 · patterns/P3-transactional-write.md
---

# P4 — Hashed, Short-Lived, Attempt-Limited Verification Code (OTP)

**Trigger:** proving someone owns an out-of-band channel — email confirmation, password reset, phone verification, 2FA — where the client is mobile-first and a clickable-link token (ASP.NET Core Identity's default `GenerateEmailConfirmationTokenAsync`/`GeneratePasswordResetTokenAsync` opaque token) doesn't fit because there's no deep-linking infrastructure to receive it. A short numeric code the user types in instead is the mobile-native shape.

**Not the same shape as `RefreshToken`'s hashed-token pattern (T1-entity.md), despite looking similar at first glance** — see the entropy note below before copying that pattern here.

---

## Entity — one per purpose, sharing a marker interface

```csharp
// <Solution>.Data/Entities/IVerificationCode.cs — pure code-reuse device, not a new architectural layer.
// Both concrete entities implement it as normal properties; EF maps each one exactly as if the
// interface didn't exist. This is what lets the service/specification below be written once.
public interface IVerificationCode
{
    Guid Id { get; set; }
    string UserId { get; set; }
    string CodeHash { get; set; }
    DateTime ExpiresAt { get; set; }
    DateTime CreatedAt { get; set; }
    int AttemptCount { get; set; }
    DateTime? ConsumedAt { get; set; } // null = active; non-null = consumed, superseded, or locked out
}

// <Solution>.Data/Entities/<Purpose>Code.cs — one concrete class per purpose (EmailConfirmationCode,
// PasswordResetCode, PhoneVerificationCode, ...). Deliberately separate tables per purpose, not one
// shared table with a Purpose/discriminator column — full schema-level isolation between otherwise-
// unrelated security-sensitive code types, at the cost of one entity+config file per purpose.
public class <Purpose>Code : IVerificationCode
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
```

Configuration: `HasKey(Id)`, `Property(CodeHash).HasMaxLength(64).IsRequired()` (SHA-256 hex is always exactly 64 chars), a **plain non-unique** index on `UserId`, cascade delete from `AppUser`. No `ICollection<...>` nav added to `AppUser` — one-directional child→parent only, matching `RefreshToken`'s precedent.

## Specification — generic across every `IVerificationCode` entity

```csharp
public class ActiveVerificationCodeByUserSpecs<TEntity> : BaseSpecification<TEntity> where TEntity : class, IVerificationCode
{
    public ActiveVerificationCodeByUserSpecs(string userId)
        : base(vc => vc.UserId == userId && vc.ConsumedAt == null)
    {
        ApplyOrderByDescending(vc => vc.CreatedAt);
    }
}
```

## Service — generate/validate written once, exposed per-purpose

```csharp
// Generate: invalidate every prior active row for this user+purpose, then insert one new hashed row.
// One SaveChangesAsync call across both steps — already atomic — no explicit transaction needed here
// unless the caller composes this with another SaveChangesAsync call (see P3).
var activeRows = await repo.ListAllWithSpecAsync(new ActiveVerificationCodeByUserSpecs<TEntity>(userId));
foreach (var stale in activeRows) { stale.ConsumedAt = DateTime.UtcNow; repo.Update(stale); }
var rawCode = tokenService.GenerateOtpCode(6);           // RandomNumberGenerator, never `Random`
var codeHash = tokenService.HashToken(rawCode);           // reuse RefreshToken's SHA-256 helper
await repo.AddAsync(/* new <Purpose>Code { CodeHash = codeHash, ExpiresAt = UtcNow.AddMinutes(10), ... } */);
await unitOfWork.SaveChangesAsync();
return rawCode; // the only place the raw code exists outside the user's inbox — never logged

// Validate: look up by (UserId, active) — NEVER by the code's hash. See "Why not lookup-by-hash" below.
var stored = await repo.GetByIdWithSpecAsync(new ActiveVerificationCodeByUserSpecs<TEntity>(userId));
if (stored is null) return NotFound;
if (stored.ExpiresAt < DateTime.UtcNow) return Expired;   // not a wrong guess — don't count it as an attempt

var presentedHash = tokenService.HashToken(code);
var isMatch = CryptographicOperations.FixedTimeEquals(   // constant-time — both sides are always 64-char hex
    Encoding.UTF8.GetBytes(presentedHash), Encoding.UTF8.GetBytes(stored.CodeHash));

if (!isMatch)
{
    stored.AttemptCount++;
    if (stored.AttemptCount >= MaxAttempts) { stored.ConsumedAt = DateTime.UtcNow; /* lock out */ }
    repo.Update(stored); await unitOfWork.SaveChangesAsync();
    return stored.ConsumedAt is null ? Invalid : LockedOut;
}

stored.ConsumedAt = DateTime.UtcNow;
repo.Update(stored); await unitOfWork.SaveChangesAsync();
return Success;
```

## Gate, don't replace, Identity's own state-change pipeline

The verification code is purely a proof-of-ownership gate. Once `ValidateAsync` returns `Success`, generate and immediately consume the real Identity token **server-side, in the same call** — never expose it to the client:

```csharp
var otpResult = await verificationService.ValidateAsync(user.Id, code);
if (otpResult != Success) return MapFailure(otpResult); // still commit — see Notes

var identityToken = await userManager.GenerateEmailConfirmationTokenAsync(user); // or GeneratePasswordResetTokenAsync
var result = await userManager.ConfirmEmailAsync(user, identityToken);           // or ResetPasswordAsync(user, token, pwd)
```

This keeps Identity's own password-policy enforcement / concurrency-stamp handling intact instead of reimplementing it — the code never bypasses `UserManager`, it only gates when `UserManager` gets called.

---

## Notes

- **Why not lookup-by-hash, the way `RefreshToken.TokenHash` works:** `RefreshToken`'s raw value has 64 bytes of entropy, so `SHA256(rawValue)` is safe as a de facto unique lookup key — collisions are practically impossible. A 6-digit code has only 1,000,000 possible values; two different users' (or two different requests') codes **will** collide on their hash at real scale. A unique index on the hash, or a specification that looks a row up "by hash" (mirroring `RefreshTokenWithSpecs`), is a real bug here — either it throws on insert or silently matches the wrong user's code. Always resolve `(UserId, purpose)` first, compare the hash only after narrowing to that one user's one active row, and always with a constant-time comparison.
- **Composing this with an outer transaction:** if the caller (e.g. a password-reset flow) needs the verification-consume step, the Identity state change, and a side effect (revoking sessions) to succeed or fail together, wrap all three in one `BeginTransactionAsync`/`CommitAsync` per P3 — but see P3's reentrancy note: any helper that opens its own transaction (like a `RevokeAllUserTokensAsync`-style helper) needs a transaction-less "core" variant to call from inside that outer transaction, since `UnitOfWork.BeginTransactionAsync()` has no reentrancy guard.
- **On a non-`Success` validation result, still commit** — `ValidateAsync` may have just persisted an attempt-count increment or a lockout; that's a real state change worth keeping even though the overall call "fails." Only roll back when the *Identity* state-change step itself fails after a valid code (that failure isn't the user's fault, so the code should stay usable).
- **Never log the raw code** — this is the one instance of a value that must never appear in a log line, per CLAUDE.md's "Logging" section; log the validation *outcome* (`Invalid`, `LockedOut`, ...), never the code itself, at either the correct or the incorrect value.
- **Rate-limit the validate endpoint at the request level too** — the attempt counter alone isn't enough; the controller action needs the same `AuthPolicy`-style throttle as every other public auth endpoint, or a client can still spray guesses across many different users' codes.
