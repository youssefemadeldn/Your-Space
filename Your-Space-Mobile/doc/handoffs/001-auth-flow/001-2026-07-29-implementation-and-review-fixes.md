# Session Handoff — 2026-07-29

> **OUT OF PREVIOUS SESSION — NEW SESSION START**
>
> Read this file first. It contains everything from the prior session.

## What Was Done

- Imported the approved Claude Design project **"Your Space Login Screen"** (`projectId aab16c46-60f5-416e-8f7f-bc4e4dd83181`, file `Auth Flow.dc.html`) via the `claude_design` MCP and extracted exact EN/AR copy, field rules, and interaction states for all 6 screens.
- Explored the codebase (3 parallel Explore agents) and cross-verified every backend claim directly against `Your-Space-Backend` source (`AuthController.cs`, `AuthService.cs`, all Auth DTOs/validators) — not inferred.
- Wrote a full implementation plan (`C:\Users\youss\.claude\plans\plan-for-use-the-luminous-hummingbird.md`), got it approved, then implemented the entire Auth feature end-to-end:
  - Fixed stale `booksplatform`/bookstore-domain leftovers in `.claude/rules/flutter_feature_prompt.md` (title + every code example genericized).
  - 3 approved core touch-points: `SnackBarHelper` (added `actionLabel`/`onAction`), `RegexHelper` (added `internationalPhone`, `accountPassword`), `ApiConstants` (added 6 endpoint path constants).
  - Full `lib/features/auth/` module: data models (7 requests + 2 responses), `AuthRemoteDataSourceImpl`, domain (`UserProfile` entity + `AuthRepository` contract), `AuthRepositoryImpl` (persists tokens on login success, clears tokens on change-password success), 6 Cubits + states, a feature-level `failure_messages.dart` override, 6 screens, routing wiring (`app_routes.dart`, `app_router.dart`, 2 args classes), `en.json`/`ar.json` `auth` namespace.
  - DI regenerated via `build_runner`.
  - Added `mocktail` as a dev dependency (`bloc_test` was **rejected** — see Bugs/Notes) and wrote unit tests: repository test, 6 cubit tests, a `failure_messages` test — all using `mocktail` + `expectLater(cubit.stream, emitsInOrder([...]))`.
  - Added one widget smoke test (`register_screen_test.dart`) — a matching `login_screen_test.dart` was attempted but hit a real `easy_localization` test-infra bug (see Bugs #6) and was deleted by the user.
- Started the real backend locally (`dotnet run`, Development mode, `http://localhost:5145`) and confirmed the API contract matches the mobile models exactly (login success shape, `Auth.InvalidCredentials` 401 shape, envelope shape) via direct `curl` calls.
- No Android emulator or iOS simulator exists on this Windows machine, and neither Flutter Web nor Windows-desktop platform support is scaffolded for this project (no `web/`/`windows/` folders) — rather than add a new platform target just for QA, the user chose to verify the 6 screens manually themselves on their own device/emulator. Handed off clear walkthrough instructions (test accounts, navigation paths, what to check per screen).
- The user then supplied an independent review (`doc/reviews/2026-07-28-auth-flow-review.md`). Every claim in it was independently re-verified (re-ran `flutter test`, re-read the flagged files) and confirmed accurate. All findings were then fixed — see Bugs Found.
- Final state: **`flutter analyze` → 0 issues. `flutter test` → 51 passed, 0 failed.**

## Bugs Found

| # | Bug | Severity | Location | Status |
|---|---|---|---|---|
| 1 | Temporary QA router changes (`initialLocation: AppRoutes.login`, throwaway `[QA] Change password` button) left un-reverted, breaking the pre-existing `widget_test.dart` smoke test | High | `lib/core/router/app_router.dart` | **Fixed** — reverted both |
| 2 | Duplicated "Android emulator alias..." comment (pasted twice back-to-back) from an earlier revert-edit | Cosmetic | `lib/core/constants/api_constants.dart` lines 4–7 | **Fixed** |
| 3 | Two unguarded `Row`s (`AppCheckbox`+link, `Text`+link) with no `Flexible`/ellipsis, per the project's own layout rule — real overflow risk on narrow devices/long Arabic text, not just a test artifact | Medium | `login_screen.dart:102`, `login_screen.dart:126`, `register_screen.dart:226` | **Fixed** — see Notes for a subtlety on *how* |
| 4 | Change Password's empty-current-password client check reused `auth.changePassword.currentPasswordIncorrect` ("Your current password is incorrect") — confusing for a field the user hasn't typed in yet, inconsistent with Register/Reset Password's distinct required-field messages | Low | `change_password_screen.dart` | **Fixed** — new key `auth.validation.requiredCurrentPassword`, old key removed from both JSON files (was orphaned) |
| 5 | `bloc_test` was planned but never added | Low (by design) | `pubspec.yaml` | **Not a bug** — `bloc_test` genuinely conflicts: it transitively requires a `test`/`test_api` version incompatible with `injectable_generator ^3.1.1` on this project's Dart SDK (version solving fails). Substituted `mocktail` + `expectLater(cubit.stream, emitsInOrder([...]))`. Now documented with a comment directly above `mocktail:` in `pubspec.yaml` so this isn't silently mysterious to the next reader. |
| 6 | Second `EasyLocalization` widget instantiated within the same test **file** (a second `testWidgets` block doing its own full pump) produced a broken tree — `Scaffold` never appeared, `find.byType(Text)` returned `[]` — even *before* any state change, while the identical setup worked fine as the file's *first* test | Medium (test-infra, not app code) | was `test/features/auth/presentation/pages/login_screen_test.dart` | **Deleted by user, not resolved.** No existing test in this codebase previously exercised >1 `EasyLocalization` instantiation per file (the only precedent, `test/core/widgets/*`, never wraps with real `EasyLocalization` at all). Likely shared static state inside `easy_localization` package. See Pending Tasks. |

## Files Changed

| File | Change | Why |
|---|---|---|
| `.claude/rules/flutter_feature_prompt.md` | Genericized title + every `Book*`/bookstore-domain code example to `<Feature>`/`<Entity>` placeholders | Task's explicit pre-work instruction |
| `lib/core/helpers/snack_bar_helper.dart` | Added optional `actionLabel`/`onAction` to all 4 show methods + private `_show` | Network-error "Retry" snackbar across all 6 screens (user's explicit choice) |
| `lib/core/helpers/regex_helper.dart` | Added `internationalPhone`, `accountPassword` | Match backend's exact phone/password validators |
| `lib/core/constants/api_constants.dart` | Added 6 endpoint path constants (register/login/confirmEmail/resendConfirmationEmail/forgotPassword/resetPassword/changePassword) | New Auth endpoints |
| `lib/core/router/app_routes.dart` | Added 4 route name/path constants | New screens |
| `lib/core/router/app_router.dart` | Added 6 `GoRoute`s + `_unknown(state)` helper | Routing wiring |
| `lib/core/router/args/confirm_email_args.dart`, `reset_password_args.dart` | New files | Typed nav args for OTP screens |
| `lib/core/di/injection_container.config.dart` | Regenerated | New `@injectable`/`@lazySingleton` classes |
| `lib/features/auth/**` (≈27 new files) | Full feature module: models, datasource, repository, entity, repository contract, 6 cubits+states, `failure_messages.dart`, 6 screens, `auth_logo_header.dart` widget | Core deliverable |
| `assets/translations/en.json`, `ar.json` | New `auth` namespace + `common.networkError`/`common.retry` | Approved design copy (EN+AR) |
| `pubspec.yaml`, `pubspec.lock` | Added `mocktail: ^1.0.5` (with explanatory comment re: `bloc_test`) | Test tooling |
| `test/features/auth/**` (8 files) | Repository test, 6 cubit tests, `failure_messages` test, `register_screen_test.dart` | Test coverage |

## Files Audited (no changes)

| File | Checked For | Result |
|---|---|---|
| `test/widget_test.dart` | Whether it's the stale default counter-app template (an earlier design-project doc claimed it was) | Confirmed **not stale** — already a valid `MyApp` smoke test. No fix needed. |
| `lib/core/widgets/*` (AppButton, AppInput, AppPasswordInput, AppOtpInput, AppAppBar, AppCheckbox, AppSwitch) | Reuse without modification per plan | Not modified. Note: `AppCheckbox`'s own internal `Row` (`app_checkbox.dart:33`) and `AppButton`'s (`app_button.dart:114`) have no overflow protection on their internal label `Text` — flagged as latent shared-widget fragility, **not fixed** (out of this feature's scope; see Pending Tasks). |
| `lib/dev/widget_gallery_main.dart` | Whether it should be deleted yet | Left in place — 2 more design passes (Core Screens, Event Screens) still need it |
| `android/gradle.properties` | Unexpected uncommitted diff (`kotlin.incremental=false` workaround) found via `git status` | Pre-existing, predates this session — **not touched, not reverted** |

## Pending Tasks

- [ ] **User to manually visually verify all 6 screens** against the approved design on their own Android emulator/device. Backend is running locally at `http://localhost:5145` (Development mode) — confirmed still up as of end of session; restart via `cd Your-Space-Backend/YourSpace.WebAPI && dotnet run --urls http://localhost:5145` if it's gone. Test accounts: `seed.active@yourspace.dev` / `Seed!Pass123` (confirmed works). Note: `seed.locked@yourspace.dev` logged in successfully instead of showing the locked-account error when tested this session — a pre-existing backend seed-data quirk, unrelated to mobile changes, don't be surprised if that path doesn't demo.
- [ ] Decide how (or whether) to add a `LoginScreen` widget smoke test given the `easy_localization` multi-instantiation issue (Bug #6) — options: merge multiple assertions into one `testWidgets` block per file (sidesteps the issue, used successfully for `register_screen_test.dart`), investigate the `easy_localization` package behavior further, or accept the coverage gap.
- [ ] Consider whether `AppCheckbox`/`AppButton` (shared `lib/core/widgets/`) need internal `Flexible`+ellipsis protection on their label text for robustness against long translations/narrow devices — out of this feature's scope, but worth a note for that widget library's own backlog.
- [ ] Nothing in this session has been committed to git yet — the user has not asked for a commit.

## What's Next (ordered)

1. User verifies the 6 auth screens end-to-end on their own device/emulator (Login incl. locked/unverified/invalid-credentials paths, Register, Confirm Email incl. wrong-code, Forgot→Reset auto-navigate, Reset Password, Change Password incl. forced logout) — both English and Arabic.
2. Report back any visual/behavioral mismatches; fix as needed.
3. Once Auth Flow is confirmed good, move to the **Core Screens** pass — same Claude Design project (`projectId aab16c46-60f5-416e-8f7f-bc4e4dd83181`), file `Core Screens.dc.html`.
4. Then the **Event Screens** pass — same project, file `Event Screens.dc.html`.
5. `lib/dev/widget_gallery_main.dart` should only be deleted after the Event Screens pass completes (per explicit instruction from the original task).

## Key References

- Plan file (full implementation spec): `C:\Users\youss\.claude\plans\plan-for-use-the-luminous-hummingbird.md`
- Independent review (already verified accurate, already fixed): `Your-Space-Mobile\doc\reviews\2026-07-28-auth-flow-review.md`
- Claude Design project "Your Space Login Screen" (`projectId aab16c46-60f5-416e-8f7f-bc4e4dd83181`): `Auth Flow.dc.html` (done), `Core Screens.dc.html` (next), `Event Screens.dc.html` (after)
- Claude Design system project "Your Space Design System" (`projectId d7e9f78e-54b1-42d1-8d71-9921cb11ec65`) — source of shared widget styling tokens
- Backend context docs: `d:\Programing\Your-Space\doc\context\project-status.md` (Auth section 2a is authoritative), `next-feature-status.md` (Groups/People/Events — relevant for the next 2 passes)
- Backend source of truth for Auth: `Your-Space-Backend\YourSpace.WebAPI\Controllers\AuthController.cs`, `Your-Space-Backend\YourSpace.Services\Services\AuthService\AuthService.cs`

## Clarifications & Decisions

| Question | Answer |
|---|---|
| Forgot Password → Reset Password transition: auto-navigate after ~1.5s, or navigate immediately with the message as a snackbar on the next screen? | Auto-navigate after ~1.5s |
| Network-error retry: keep `SnackBarHelper` as-is (no action button), or extend it with an action slot? | Extend `SnackBarHelper` with an action slot |
| Should this pass include writing unit tests for the 6 cubits + repository (requires adding a mocking library)? | Yes — add `mocktail` + `bloc_test` and write tests (note: `bloc_test` itself turned out impossible due to a real version conflict; substituted `mocktail`-only, documented in `pubspec.yaml`) |
| Visual verification: no Android emulator/iOS simulator on this machine, Flutter Web/Windows-desktop not scaffolded — 3 options offered (add Windows-desktop temporarily / user verifies manually / skip live verification and rely on code review) | User verifies manually themselves on their own device/emulator |
| "read the ...review... and ask is this right?" | Independently re-verified every claim (re-ran `flutter test`, re-read flagged files) — confirmed accurate, added 2 pieces of context the code-only review couldn't have known (why `bloc_test` is missing; why the TEMP-VERIFY revert was pending, not forgotten) |
| "okay plan to fix or fix it" | Took as go-ahead to fix directly; applied all review-recommended fixes without further planning |
| "i deleted the logn test entirly, run all tests now" | Confirmed `login_screen_test.dart` deletion, ran full suite — 51 passed, 0 failed |

## Notes

- Package name is `your_space_mobile` (not `booksplatform` — that stale reference is now fully fixed in `flutter_feature_prompt.md`).
- Root `CLAUDE.md` still documents the two projects at paths `.net/`/`flutter/`, which don't exist — actual folders are `Your-Space-Backend/`/`Your-Space-Mobile/`. Pre-existing doc drift, out of this task's scope, flagged for awareness only.
- The Row-overflow fix (Bug #3) taught a reusable lesson: wrapping **both** children of a `Row` in equally-flexed `Flexible` forces a 50/50 split, which can squeeze a naturally-short sibling (e.g. `AppCheckbox`) below its own needs. The correct fix is asymmetric — leave the short/fixed side at its natural size, and only wrap the variable-length side (the one that could genuinely grow, e.g. a translated link) in `Flexible` + `overflow: TextOverflow.ellipsis`.
- The widget-test viewport issue (surfaced while chasing Bug #6) is also worth remembering for future test files: `tester.binding.setSurfaceSize(...)` only resizes the *rendering surface* — it does **not** change what `MediaQuery.of(context).size` reports, so `ScreenUtil` (which reads `MediaQuery.size`) keeps scaling as if the screen were still the default ~800×600 test surface. `tester.view.physicalSize`/`tester.view.devicePixelRatio` is what actually needs to change for `ScreenUtil` to compute a realistic scale factor in tests.
- Local backend was left running (`dotnet run`, Development, `http://localhost:5145`) as a detached background process — confirmed still reachable at end of session. No Postgres/Redis issues; Redis (port 6379) isn't running but the backend doesn't actually consume it (registered, unused — a separate pre-existing backend-side note, not this session's concern).
- Nothing in this session has been committed to git.
