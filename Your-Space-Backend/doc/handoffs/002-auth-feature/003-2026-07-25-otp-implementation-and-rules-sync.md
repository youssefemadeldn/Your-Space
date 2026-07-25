# Session Handoff — 2026-07-25

> **OUT OF PREVIOUS SESSION — NEW SESSION START**
>
> Read this file first. It contains everything from the prior session.

## What Was Done

1. **Planned and implemented the OTP switch** decided at the end of the prior session (`doc/handoffs/002-auth-feature/002-2026-07-25-live-test-and-otp-decision.md`) — replaced ASP.NET Core Identity's long opaque token with a 6-digit numeric OTP for both email-confirmation and password-reset. Planned via `EnterPlanMode` first, per the user's explicit instruction from last session; plan file: `C:\Users\youss\.claude\plans\yes-plan-for-this-jaunty-kitten.md`.
2. **User decisions locked in before implementation** (see "Clarifications & Decisions" below): two separate tables (`EmailConfirmationCode`, `PasswordResetCode`), not one shared table with a purpose column; also fold in a pre-existing gap found during planning — `AuthController.ConfirmEmail` had **no rate limiting at all** (every other auth endpoint did) — fixed as part of this change, not filed separately.
3. **Built the full feature**:
   - **Data**: `IOtpCode` marker interface (`YourSpace.Data/Entities/IOtpCode.cs`) implemented by two concrete entities, `EmailConfirmationCode.cs` and `PasswordResetCode.cs` — same hashed-token shape as `RefreshToken`, but **looked up by `(UserId, not-yet-consumed)`, never by hash** (a 6-digit code's keyspace is too small for hash-uniqueness to be safe, unlike `RefreshToken`'s 64-byte token). Configurations add a plain non-unique index on `UserId` each. `YourSpaceDbContext` gained two `DbSet`s.
   - **Repository**: one generic spec, `ActiveOtpCodeByUserSpecs<TEntity> where TEntity : class, IOtpCode`, reused for both entities.
   - **Services**: `OtpConstants` (`CodeLength=6`, `ExpiryMinutes=10`, `MaxAttempts=5`), `OtpValidationResult` enum (`Success`/`NotFound`/`Expired`/`Invalid`/`LockedOut`), `IOtpService`/`OtpService` (4 public methods — `Generate`/`Validate` × `EmailConfirmationCode`/`PasswordResetCode` — each delegating to a shared private generic method). `ITokenService` gained `GenerateOtpCode(int length)` (CSPRNG-backed).
   - **`AuthService.cs` rewritten**: `RegisterAsync`, `ConfirmEmailAsync`, `ResendConfirmationEmailAsync`, `ForgotPasswordAsync`, `ResetPasswordAsync` all switched to OTP. The OTP is purely a proof-of-ownership gate — on success, `AuthService` internally calls Identity's own `GenerateEmailConfirmationTokenAsync`+`ConfirmEmailAsync` (or the password-reset equivalents) server-side in the same call, never exposing that token to the client. **Fixed a real nested-transaction bug in the process**: `UnitOfWork.BeginTransactionAsync()` has no reentrancy guard, so wrapping `ResetPasswordAsync` in its own transaction while it called the old `RevokeAllUserTokensAsync` (which always opened its own transaction) would have thrown at runtime. Fixed by splitting it into `RevokeAllActiveTokensCoreAsync` (no transaction handling) + a thin `RevokeAllUserTokensAsync` wrapper.
   - **DTOs**: `ConfirmEmailDto` changed from `{UserId, Token}` to `{Email, Code}` (UX consistency — user always types email+code, never a raw UserId). `ResetPasswordDto.Token` → `.Code`.
   - **WebAPI**: `IOtpService` registered `Scoped` in `ServiceRegistration.cs`. `AuthController.ConfirmEmail` changed from `[HttpGet]`+`[FromQuery]` to `[HttpPost]`+`[FromBody]`, and gained `[EnableRateLimiting(RateLimitingExtension.AuthPolicy)]` (the gap mentioned above).
4. **Migration `AddOtpCodes`** created and applied to local Postgres — two new tables, `EmailConfirmationCodes` and `PasswordResetCodes`, each with a non-unique `UserId` index and cascade delete from `AspNetUsers`. File: `YourSpace.Data/Migrations/20260725125825_AddOtpCodes.cs`.
5. **Tests**: updated all 10 existing `AuthService_*Tests.cs` files (new `IOtpService` mock param, DTO field renames, OTP result branching, transaction commit/rollback assertions) plus the one integration test (`AuthControllerTests.cs`, confirm-email now `POST`ed with the code parsed out of the email's `<h2>` tag instead of GET query params). Added 2 new test files, `Unit/Services/OtpService/OtpService_GenerateAsyncTests.cs` and `OtpService_ValidateAsyncTests.cs`. **51/51 tests passing.**
6. **Live-verified end-to-end against the real dev server and a real inbox** — used the newly-available Gmail MCP tools (`mcp__claude_ai_Gmail__search_threads`) to read actual OTP codes sent to `youssefemad63.ye+otptest1@gmail.com` (Gmail plus-addressing under the user's real inbox). Verified: register → real code arrives by email → confirm succeeds → replaying the same code is correctly rejected (400) → login works. Then forgot-password → new code arrives → wrong code rejected (400) → correct code resets the password → old password rejected, new one works → the pre-reset refresh token is correctly revoked (401, "has been revoked"). No unhandled exceptions in the server log during any of this — confirms both the nested-transaction fix and the ambient-transaction-sharing assumption between `AuthService`/`OtpService` (both `Scoped`, same `DbContext` per request) hold up under a real process, not just mocks.
7. **Housekeeping**: killed a leftover `dotnet run` process (PID 9396) from the *prior* session that was still running and locking the build output — worth noting this is a recurring minor friction point (ending a session with the dev server still up).
8. **Ran `/dotnet-rules-sync`** to codify this as a durable pattern so it isn't re-derived from scratch next time (see "Files Changed" below for the rule-file diffs).

## Bugs Found

| # | Bug | Severity | Location | Status |
|---|---|---|---|---|
| 1 | `AuthController.ConfirmEmail` had no `[EnableRateLimiting]` at all — every other public auth endpoint did | Real gap, found during planning | `AuthController.cs` | **Fixed** — added `[EnableRateLimiting(RateLimitingExtension.AuthPolicy)]` |
| 2 | `UnitOfWork.BeginTransactionAsync()` has no reentrancy guard; wrapping `ResetPasswordAsync` in its own transaction while it called the old `RevokeAllUserTokensAsync` (which always opened its own transaction) would throw at runtime — only surfaces on a real call, not in a mocked unit test | Critical, caught during design (not live-discovered this time) | `AuthService.cs` | **Fixed** — split into transaction-less `RevokeAllActiveTokensCoreAsync` + thin `RevokeAllUserTokensAsync` wrapper. Now also documented as a standing gotcha in `patterns/P3-transactional-write.md`. |
| 3 | C# compiler error CS9040: `new TEntity()` under a generic `new()` constraint doesn't work when `TEntity` declares `required` members | Build-time only, not a runtime bug | `OtpService.cs` `GenerateAsync<TEntity>` | **Fixed** — switched to a factory-delegate parameter (`Func<string,string,DateTime,DateTime,TEntity>`) supplied by each public method instead of a `new()` constraint. Worth remembering if this generic-entity-factory shape is reused elsewhere. |

## Files Changed

| File | Change | Why |
|---|---|---|
| `YourSpace.Data/Entities/IOtpCode.cs` | New | Shared shape for generic OTP service/spec code |
| `YourSpace.Data/Entities/EmailConfirmationCode.cs`, `PasswordResetCode.cs` | New | Two separate tables per the user's decision |
| `YourSpace.Data/Configurations/EmailConfirmationCodeConfiguration.cs`, `PasswordResetCodeConfiguration.cs` | New | Non-unique `UserId` index each, cascade delete |
| `YourSpace.Data/Contexts/YourSpaceDbContext.cs` | Added 2 `DbSet`s | — |
| `YourSpace.Data/Migrations/20260725125825_AddOtpCodes.*` | New migration | Applied to local Postgres |
| `YourSpace.Repository/Specifications/AuthSpecifications/ActiveOtpCodeByUserSpecs.cs` | New, generic | Reused by both entities |
| `YourSpace.Services/Services/OtpService/*` | New (`OtpConstants`, `OtpValidationResult`, `IOtpService`, `OtpService`) | Core feature |
| `YourSpace.Services/Services/TokenService/ITokenService.cs`, `TokenService.cs` | Added `GenerateOtpCode(int)` | CSPRNG-backed raw code generation |
| `YourSpace.Services/Services/AuthService/Dtos/ConfirmEmailDto.cs`, `ResetPasswordDto.cs` | Field renames | `UserId`/`Token` → `Email`/`Code` |
| `YourSpace.Services/Validators/OtpCodeValidationRules.cs` | New | Shared 6-digit format rule |
| `YourSpace.Services/Validators/ConfirmEmailDtoValidator.cs`, `ResetPasswordDtoValidator.cs` | Updated rules | Match new DTO shape |
| `YourSpace.Services/Services/AuthService/AuthService.cs` | Major rewrite | See "What Was Done" #3 |
| `YourSpace.WebAPI/Helpers/ServiceRegistration.cs` | Registered `IOtpService` (Scoped) | — |
| `YourSpace.WebAPI/Controllers/AuthController.cs` | `ConfirmEmail`: GET→POST, added rate limiting | See Bug #1 |
| `YourSpace.WebAPI.Tests/Unit/Services/AuthService/*.cs` (10 files) | Updated for new DI param + DTO shape | — |
| `YourSpace.WebAPI.Tests/Unit/Services/OtpService/*.cs` (2 new files) | New unit tests | Generate/Validate coverage |
| `YourSpace.WebAPI.Tests/Integration/Controllers/AuthControllerTests.cs` | Updated confirm-email call | New POST+body shape |
| `.claude/templates/patterns/P4-hashed-verification-code.md` | New pattern file | Codifies this mechanism for reuse (phone verification, 2FA, etc.) |
| `.claude/templates/patterns/P3-transactional-write.md` | Added reentrancy-guard note | See Bug #2 |
| `.claude/rules/dotnet_feature_prompt.md` | §4 bullet, §7 anti-pattern row, §6 checklist line — all pointers to P4 | Discoverability |
| `.claude/templates/layers/T2-repository.md` | Notes bullet + `governed-by` frontmatter | P4 is fundamentally a spec-design pattern |

## Files Audited (no changes)

| File | Checked For | Result |
|---|---|---|
| Whole solution | `dotnet build` | 0 warnings, 0 errors |
| Whole solution | `dotnet test` | 51/51 passing |
| `ArchitectureLayeringTests.cs` | Layer boundaries, DTO/entity separation | Still passes, no hardcoded entity lists needed updating |

## Pending Tasks

This feature is complete, tested, live-verified, and codified into rules — nothing left in-scope for it. Deferred items noted but **not** acted on this session:

- [ ] Mobile app (`Your-Space-Mobile`) has no auth screens built yet — when they are built, they need to POST `{email, code}` to `confirm-email` and `{email, code, newPassword, confirmNewPassword}` to `reset-password` (both changed shape this session).
- [ ] Email deliverability to spam (noted last session, Gmail SMTP sender reputation) — still unresolved, out of scope for this session.
- [ ] Test/leftover accounts in the local dev DB: `youssefemadeldin39@gmail.com`, `youssefemad63.ye+test1@gmail.com` (from the prior session) and `youssefemad63.ye+otptest1@gmail.com` (this session's live test) — can be deleted or left alone.
- [ ] Optional future hardening flagged in the plan but deliberately not built: a partial unique index on `(UserId) WHERE ConsumedAt IS NULL` per OTP table to close a residual double-tap race window — needs its own `DbUpdateException` handling if adopted later.

## What's Next (ordered)

No specific next step is queued — this closes out the auth feature's OTP work. Ask the user what to tackle next; likely candidates based on prior sessions' notes: admin-management endpoints (deliberately deferred, see `002-...md`), or starting the mobile-side auth screens now that the backend contract is stable.

## Key References

- This session's plan: `C:\Users\youss\.claude\plans\yes-plan-for-this-jaunty-kitten.md`
- New reusable pattern doc: `Your-Space-Backend/.claude/templates/patterns/P4-hashed-verification-code.md`
- Backend rules: `Your-Space-Backend/CLAUDE.md`, `.claude/rules/dotnet_feature_prompt.md`, `.claude/templates/layers/T2-repository.md`, `.claude/templates/patterns/P3-transactional-write.md`
- Prior handoff: `doc/handoffs/002-auth-feature/002-2026-07-25-live-test-and-otp-decision.md`
- Local dev server: `dotnet run --launch-profile http` from `YourSpace.WebAPI/` → `http://localhost:5145`

## Clarifications & Decisions

| Question | Answer |
|---|---|
| Single shared `OtpCode` table (with a `Purpose` enum) or two separate tables? | **Two separate tables** (`EmailConfirmationCode`, `PasswordResetCode`) — full schema-level isolation, at the cost of slightly more boilerplate (mitigated via the shared `IOtpCode` interface + generic service/spec) |
| Fold the pre-existing missing-rate-limit gap on `ConfirmEmail` into this change, or file separately? | **Fix it now** — directly relevant since the endpoint now verifies a brute-forceable 6-digit code |

## Notes

- Gmail MCP tools (`mcp__claude_ai_Gmail__*`) are available and were used this session for the first time to read real OTP codes out of the user's actual inbox during the live smoke test — useful precedent if a similar "read the real email" verification is needed again.
- The `/dotnet-rules-sync` skill run this session is a good precedent for how to close out a feature: implement → live-verify → codify the non-obvious design decisions into `.claude/templates/patterns/` so the next session (or a different feature needing the same shape, e.g. phone verification or 2FA) doesn't re-derive the hash-collision/transaction-reentrancy gotchas from scratch.
