# Account Deletion Audit — Your-Space monorepo

**Date:** 2026-09-01
**Scope:** Backend (`Your-Space-Backend`) + Mobile (`Your-Space-Mobile`)
**Method:** Static code search + read. No code changes made.

---

## TL;DR

| Question | Answer |
|---|---|
| Does account deletion exist today? | **No.** Nothing in either project deletes, closes, or deactivates a user account. |
| Level implemented | **Nothing** — not full-delete, not deactivate-only, not even a stubbed endpoint or flag. |
| Backend natural insertion point | `AuthController` + `IAuthService` / `AuthService` (e.g. `DELETE /api/v1/auth/me`). |
| Mobile natural insertion point | **No Settings or Profile screen exists.** One must be created (`lib/features/settings/…`), reached from the gear/overflow slot in `HomeScreen`'s app bar. The only account-level action in the UI today is **Logout**, inlined in `home_screen.dart`. |
| FK / cascade concerns | Owned data (`Person`, `Group`, `Event`, `UserSettings`, tokens, OTP codes) is `ON DELETE CASCADE` to `AspNetUsers`. **But** `Person → Group` is `ON DELETE RESTRICT`, and both `Person` and `Group` cascade-delete from the same user row — PostgreSQL does not guarantee the order, so a naive `UserManager.DeleteAsync` can intermittently throw a FK violation. A real hard-delete needs an ordered, transactional teardown. `OwnerUserId` is non-nullable, so `SET NULL` is not an option without a model change. |

---

## 1. Backend — `Your-Space-Backend`

### 1.1 Is there a delete/deactivate endpoint?

**No.** Full inventory of `AuthController`
([`YourSpace.WebAPI/Controllers/AuthController.cs`](../../Your-Space-Backend/YourSpace.WebAPI/Controllers/AuthController.cs)):

| Route | Method | Purpose |
|---|---|---|
| `POST /api/v1/auth/register` | `Register` | create account |
| `POST /api/v1/auth/login` | `Login` | |
| `POST /api/v1/auth/refresh-token` | `RefreshToken` | |
| `POST /api/v1/auth/revoke-token` | `RevokeToken` | logout (revokes one refresh token) |
| `POST /api/v1/auth/confirm-email` | `ConfirmEmail` | |
| `POST /api/v1/auth/resend-confirmation-email` | `ResendConfirmationEmail` | |
| `POST /api/v1/auth/forgot-password` | `ForgotPassword` | |
| `POST /api/v1/auth/reset-password` | `ResetPassword` | |
| `POST /api/v1/auth/change-password` | `ChangePassword` | |
| `GET /api/v1/auth/me` | `GetProfile` | |

There is **no** `DELETE` verb anywhere in the controller, and no "deactivate" / "close" / "disable" action.

`IAuthService`
([`YourSpace.Services/Services/AuthService/IAuthService.cs`](../../Your-Space-Backend/YourSpace.Services/Services/AuthService/IAuthService.cs))
has 10 methods — `RegisterAsync`, `LoginAsync`, `RefreshTokenAsync`, `RevokeTokenAsync`, `ConfirmEmailAsync`, `ResendConfirmationEmailAsync`, `ForgotPasswordAsync`, `ResetPasswordAsync`, `ChangePasswordAsync`, `GetProfileAsync` — **none** delete or deactivate a user.

**Other controllers** — `GroupsController`, `PersonsController`, `EventsController`, `PersonOccasionHistoryController`, `EventGuestsController`, `UserSettingsController` — each have a `DeleteAsync` but it operates on *that feature's* row (a group / person / event / history row), scoped to `GetUserId()`. None touch `AppUser`.

**Grep evidence:**
- `deleteaccount|deactivat|disableuser|removeaccount|closeaccount|IsDeleted|IsActive|SoftDelete` across `*.cs` → **only** matches are auto-generated `LockoutEnabled` columns in Identity migrations.
- `userManager.Delete | Users.Remove | DeleteAsync(user) | RemoveAsync(user)` → **zero** matches. (`GenericRepository.Delete` — a hard `context.Set<T>().Remove(entity)` — exists at
  [`YourSpace.Repository/Repositories/GenericRepository.cs:38`](../../Your-Space-Backend/YourSpace.Repository/Repositories/GenericRepository.cs#L38) but is never invoked for `AppUser`.)

### 1.2 The `AppUser` entity — no soft-delete / disable flag

[`YourSpace.Data/Entities/AppUser.cs`](../../Your-Space-Backend/YourSpace.Data/Entities/AppUser.cs):

```csharp
public class AppUser : IdentityUser
{
    [MaxLength(100)]
    public required string FirstName { get; set; }

    [MaxLength(100)]
    public required string LastName { get; set; }
}
```

- **No** custom `IsActive` / `IsDeleted` / `ClosedAt` / `DeletedAt` field.
- ASP.NET Identity's default `LockoutEnabled` / `LockoutEnd` columns exist on `AspNetUsers` (from `InitialCreate`), but the codebase uses lockout **only** for OTP brute-force throttling inside `AuthService` (`Otp.LockedOut` error path) — there is no "the account is closed" use of it, and `LoginAsync` has no closed/disabled check.
- Contrast with the feature entities: `Person`, `Group`, `Event` each carry a nullable `DeletedAt` and their `DeleteAsync` sets it (soft delete — e.g.
  [`PersonService.cs:151`](../../Your-Space-Backend/YourSpace.Services/Services/PersonService/PersonService.cs#L151),
  [`GroupService.cs:103`](../../Your-Space-Backend/YourSpace.Services/Services/GroupService/GroupService.cs#L103)).
  `AppUser` has no equivalent.

### 1.3 Related data owned by / referencing a user

All "owned" entities key off a **non-nullable** `OwnerUserId` / `UserId` string FK to `AspNetUsers`:

| Entity | FK column | `OnDelete` (EF config + migration) | Soft-delete? |
|---|---|---|---|
| `Group` | `OwnerUserId` | **Cascade** — [`GroupConfiguration.cs:15`](../../Your-Space-Backend/YourSpace.Data/Configurations/GroupConfiguration.cs#L15) | `DeletedAt` (soft) |
| `Person` | `OwnerUserId` | **Cascade** — [`PersonConfiguration.cs:16`](../../Your-Space-Backend/YourSpace.Data/Configurations/PersonConfiguration.cs#L16) | `DeletedAt` (soft) |
| `Person` | `GroupId` | **Restrict** — [`PersonConfiguration.cs:24`](../../Your-Space-Backend/YourSpace.Data/Configurations/PersonConfiguration.cs#L24) | — |
| `Event` | `OwnerUserId` | **Cascade** — [`EventConfiguration.cs:15`](../../Your-Space-Backend/YourSpace.Data/Configurations/EventConfiguration.cs#L15) | `DeletedAt` (soft) |
| `EventGuest` | `EventId`, `PersonId` | **Cascade** (both) — [`EventGuestConfiguration.cs:18`](../../Your-Space-Backend/YourSpace.Data/Configurations/EventGuestConfiguration.cs#L18) | hard-delete row |
| `PersonOccasionHistory` | `PersonId` | **Cascade** — [`PersonOccasionHistoryConfiguration.cs:16`](../../Your-Space-Backend/YourSpace.Data/Configurations/PersonOccasionHistoryConfiguration.cs#L16) | hard-delete row |
| `UserSettings` | `UserId` (also PK, 1:1) | **Cascade** — [`UserSettingsConfiguration.cs:13`](../../Your-Space-Backend/YourSpace.Data/Configurations/UserSettingsConfiguration.cs#L13) | lazily created |
| `RefreshToken` | `UserId` | **Cascade** — [`RefreshTokenConfiguration.cs:17`](../../Your-Space-Backend/YourSpace.Data/Configurations/RefreshTokenConfiguration.cs#L17) | — |
| `EmailConfirmationCode` | `UserId` | **Cascade** — [`EmailConfirmationCodeConfiguration.cs:19`](../../Your-Space-Backend/YourSpace.Data/Configurations/EmailConfirmationCodeConfiguration.cs#L19) | — |
| `PasswordResetCode` | `UserId` | **Cascade** — [`PasswordResetCodeConfiguration.cs:19`](../../Your-Space-Backend/YourSpace.Data/Configurations/PasswordResetCodeConfiguration.cs#L19) | — |

Migration constraints match the EF config — see
[`20260726202448_AddPeopleGroupsEventsFeature.cs`](../../Your-Space-Backend/YourSpace.Data/Migrations/20260726202448_AddPeopleGroupsEventsFeature.cs)
lines 103–113 (`FK_People_AspNetUsers_OwnerUserId` = `Cascade`, `FK_People_Groups_GroupId` = `Restrict`).

### 1.4 Cascade / FK concerns for a *real* delete implementation

1. **`Person → Group` is `RESTRICT`, and both cascade from the same user row.**
   Deleting the `AspNetUsers` row triggers DB cascade to **both** the user's `People` rows **and** their `Groups` rows. `FK_People_Groups_GroupId` is `ON DELETE RESTRICT`. PostgreSQL does not guarantee the processing order of multiple cascade paths originating from one `DELETE`; if a `Groups` row is deleted while a `People` row still references it, the RESTRICT constraint raises a foreign-key violation and the whole delete aborts. A naive `UserManager.DeleteAsync(user)` / `Users.Remove(user)` is therefore **not safe** here.
   → A real hard-delete needs an explicit, ordered, transactional teardown, e.g.:
   `EventGuests` + `PersonOccasionHistories` → `People` → `Events` → `Groups` → `UserSettings` / `RefreshTokens` / `EmailConfirmationCodes` / `PasswordResetCodes` → `AspNetUserRoles` / `AspNetUserClaims` / `AspNetUserLogins` / `AspNetUserTokens` (Identity) → `AspNetUsers`.
   `AuthService` already uses `unitOfWork.BeginTransactionAsync()` / `CommitAsync` / `RollbackAsync` (see `RefreshTokenAsync`), so the transactional pattern is in place.

2. **`OwnerUserId` / `UserId` are non-nullable `required string`.**
   "Anonymize instead of delete" (`SET NULL` on the owner FK) is impossible without a schema/model change.

3. **Soft-deleted rows are still real rows.**
   `Person` / `Group` / `Event` rows with `DeletedAt` set still hold live FK references, so a hard delete of the user must include them in the teardown. Conversely, a *soft* "close account" that only flips a flag on `AppUser` would leave all owned data physically present — acceptable for GDPR "deactivate" semantics, but a follow-up purge job would still hit concern #1.

4. **Identity satellite tables** (`AspNetUserRoles`, `AspNetUserClaims`, `AspNetUserLogins`, `AspNetUserTokens`) cascade via Identity's own model config and are handled correctly by `UserManager.DeleteAsync`; they are only a concern if the delete is done with raw SQL / `context.Remove` instead of `UserManager`.

### 1.5 Natural backend insertion point

- **Endpoint:** `AuthController` — add `[HttpDelete("me")] [Authorize] DeleteAccount()` calling `authService.DeleteAccountAsync(GetUserId())`, returning `new ResultActionResult(result)`. Mirrors the existing `GetProfile` / `ChangePassword` shape (`[Authorize]` + `GetUserId()` + `ResultActionResult`).
- **Service:** `AuthService` — already injects `UserManager<AppUser>`, `IUnitOfWork` (with transaction helpers), `ILogger`. Best home for the ordered teardown described in 1.4. Add `DeleteAccountAsync(string userId)` to `IAuthService`.
- **Alternative (soft "deactivate"):** add `ClosedAt` / `IsClosed` to `AppUser` + a new migration, set it in `DeleteAccountAsync`, and add a check in `LoginAsync` / `RefreshTokenAsync`. No existing flag can be reused for this.
- Consider also revoking all refresh tokens (`RevokeAllUserTokensAsync` already exists as a private helper in `AuthService`).

---

## 2. Mobile — `Your-Space-Mobile`

### 2.1 Is there a "Delete account" UI entry point?

**No.** Grep for `delete account | delete my account | deleteaccount | close account | deactivate` across `lib/**/*.dart` → **zero** matches.

### 2.2 Is there a Settings or Profile screen?

**No Settings screen and no Profile screen exist.**

- Feature folders under [`lib/features/`](../../Your-Space-Mobile/lib/features/): `auth`, `events`, `groups`, `home`, `people`. There is no `settings/` or `profile/` feature.
- Files matching `*setting*` / `*profile*` / `*account*`:
  - [`lib/core/widgets/app_profile_row.dart`](../../Your-Space-Mobile/lib/core/widgets/app_profile_row.dart) — a **reusable list row** (avatar + name + group pill + trailing), used in People / Event Guests / Add-Guests / Reciprocity lists. **Not** a profile screen.
  - [`lib/features/auth/domain/entities/user_profile.dart`](../../Your-Space-Mobile/lib/features/auth/domain/entities/user_profile.dart) and `.../data/models/user_profile_response.dart` — the DTO/entity for `GET /auth/me`. No screen renders them.
- Routes ([`lib/core/router/app_routes.dart`](../../Your-Space-Mobile/lib/core/router/app_routes.dart)): `splash`, `login`, `register`, `confirmEmail`, `forgotPassword`, `resetPassword`, `changePassword`, `home`, `groups`, `people`, `personForm`, `personDetails`, `events`, `eventForm`, `eventDetails`, `eventGuests`, `addGuests`, `reciprocitySuggestions`, `unknown`. **No `settings` or `profile` route.**
- Bottom nav ([`lib/core/widgets/app_bottom_nav.dart`](../../Your-Space-Mobile/lib/core/widgets/app_bottom_nav.dart)) is a fixed 4-item **Home / Groups / People / Events**. No Settings tab.

### 2.3 What account-level actions the UI has today

**Only Logout**, implemented inline in the Home screen's app bar
([`lib/features/home/presentation/pages/home_screen.dart`](../../Your-Space-Mobile/lib/features/home/presentation/pages/home_screen.dart)):

```dart
// home_screen.dart:31-38  — AppBar trailing action
appBar: AppAppBar(
  title: 'home.title'.tr(),
  trailing: IconButton(
    icon: const Icon(Icons.logout_rounded),
    tooltip: 'common.logout'.tr(),
    onPressed: () => _confirmLogout(context),
  ),
),
```

```dart
// home_screen.dart:57-69
void _confirmLogout(BuildContext context) {
  getIt<DialogHelper>().showConfirmDialog(
    title: 'common.logoutConfirmTitle'.tr(),
    message: 'common.logoutConfirmMessage'.tr(),
    confirmText: 'common.logout'.tr(),
    cancelText: 'common.cancel'.tr(),
    onConfirm: () async {
      await getIt<SecureStorageHelper>().clearSession();
      if (!context.mounted) return;
      context.go(AppRoutes.login);
    },
  );
}
```

This `clearSession()` + `context.go(AppRoutes.login)` teardown is exactly what a successful "delete account" flow would also run.

### 2.4 The already-built, unreachable Change-Password screen

- [`lib/features/auth/presentation/pages/change_password_screen.dart`](../../Your-Space-Mobile/lib/features/auth/presentation/pages/change_password_screen.dart) exists, wired to `change_password_cubit` and registered on route `/change-password`
  ([`app_router.dart:121`](../../Your-Space-Mobile/lib/core/router/app_router.dart#L121)).
- **Nothing navigates to it.** Grep for `.go(AppRoutes.changePassword)` / `.push(...)` / `goNamed` / `pushNamed` → **zero** call sites.
- This is the strongest signal that a **Settings screen is the missing host** — it would naturally contain Change Password (wire up the existing screen), Logout (move it here from Home), and Delete Account.

### 2.5 Auth data layer — no delete method

- [`auth_remote_data_source_impl.dart`](../../Your-Space-Mobile/lib/features/auth/data/datasources/auth_remote_data_source_impl.dart): `register`, `login`, `confirmEmail`, `resendConfirmationEmail`, `forgotPassword`, `resetPassword`, `changePassword`. No delete.
- [`base_auth_repository.dart`](../../Your-Space-Mobile/lib/features/auth/domain/repositories/base_auth_repository.dart) / `auth_repository_impl.dart`: same set. No delete.
- [`api_constants.dart`](../../Your-Space-Mobile/lib/core/constants/api_constants.dart): no delete-account path constant.

### 2.6 Natural mobile insertion point

A Settings screen must be **created** (none exists). Following the project's existing feature structure:

1. **New feature:** `lib/features/settings/presentation/pages/settings_screen.dart` + a `delete_account_cubit` (mirror `change_password_cubit`).
2. **Route:** add `settings = '/settings'` to `AppRoutes` and register it in `app_router.dart`.
3. **Entry point:** replace the bare logout `IconButton` in `HomeScreen`'s `AppAppBar` (`home_screen.dart:33`) with a settings/gear `IconButton` → `context.push(AppRoutes.settings)`; move Logout into the Settings screen. (Bottom nav is fixed at 4 items — do not add a 5th tab.)
4. **Settings screen contents:** Change Password (navigate to the already-built `/change-password`), Logout (the `_confirmLogout` logic moved from Home), **Delete Account** (confirm dialog via `DialogHelper.showConfirmDialog`, ideally a typed-confirmation or password re-entry given it is destructive).
5. **Data layer:** add `ApiConstants.deleteAccount` (e.g. `'/auth/me'` with `DELETE`), a `deleteAccount()` method to `base_auth_repository.dart` + impl + `auth_remote_data_source_impl.dart`, returning `Either<Failure, Unit>` — copy the `changePassword` implementation shape.
6. **On success:** run the same teardown as logout — `SecureStorageHelper.clearSession()` then `context.go(AppRoutes.login)`.

---

## 3. Summary of file paths touched by a future implementation

**Backend (create/modify):**
- `YourSpace.WebAPI/Controllers/AuthController.cs` — new `DELETE me` action
- `YourSpace.Services/Services/AuthService/IAuthService.cs` + `AuthService.cs` — `DeleteAccountAsync` with ordered transactional teardown
- (if soft-close) `YourSpace.Data/Entities/AppUser.cs` + new migration + `LoginAsync` guard

**Mobile (create):**
- `lib/features/settings/presentation/pages/settings_screen.dart` (new)
- `lib/features/settings/presentation/cubit/delete_account_cubit/` (new)
- `lib/core/router/app_routes.dart` + `app_router.dart` — `/settings` route
- `lib/features/home/presentation/pages/home_screen.dart` — swap logout icon for settings icon
- `lib/core/constants/api_constants.dart` — `deleteAccount` path
- `lib/features/auth/domain/repositories/base_auth_repository.dart` + `data/repositories/auth_repository_impl.dart` + `data/datasources/auth_remote_data_source_impl.dart` — `deleteAccount()`

---

## 4. Key risk to carry forward

The single non-obvious correctness risk is **§1.4 item 1**: `Person → Group` is `ON DELETE RESTRICT` while both `Person` and `Group` cascade-delete from the same `AspNetUsers` row. A one-line `UserManager.DeleteAsync(user)` will *sometimes* work and *sometimes* throw a FK violation depending on PostgreSQL's cascade ordering. The delete must be an explicit, dependency-ordered teardown inside a transaction.
