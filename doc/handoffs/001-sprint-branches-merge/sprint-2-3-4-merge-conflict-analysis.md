# Pre-Merge Conflict Analysis — sprint-2 / sprint-3 / sprint-4 into production

**Date:** 2026-09-03
**Method:** Simulated in a disposable git worktree (`git worktree add --detach /tmp/merge-sim production`, `git merge --no-commit --no-ff origin/sprint-2/post-launch-feedback`, then `git merge --abort` + `git worktree remove --force`). **Nothing was committed or pushed** — this is a dry-run finding, not a completed merge.

---

## Branch shape

`sprint-2`, `sprint-3`, `sprint-4` are **stacked**, not independent siblings:

```
sprint-1  →  sprint-2  →  sprint-3  →  sprint-4
(merged      (forked      (forked      (forked
 into         from         from         from
 production)  sprint-1     sprint-2     sprint-3
              tip)         tip)         tip)
```

Confirmed via `git merge-base`:
- `merge-base(sprint-2, sprint-1) == sprint-1 tip (105d0ac)`
- `merge-base(sprint-3, sprint-2) == sprint-2 tip (c6997fa)`
- `merge-base(sprint-4, sprint-3) == sprint-3 tip (86ea507)`

None of sprint-2/3/4 know about commits that landed on `production` **after** sprint-1 forked off:

- `cc18cfe` — feat: add full account deletion (Apple 5.1.1(v) fix)
- `63b8c22` — fix: reject a new password identical to the current one
- `089c096` — chore: update iOS deployment target to 15.0 and bump version

(`git merge-base --is-ancestor cc18cfe origin/sprint-1/post-launch-feedback` → false, confirms this.)

---

## Simulated sprint-2 → production merge result

**13 files conflicted:**

```
Your-Space-Backend/YourSpace.Services/Services/AuthService/AuthService.cs
Your-Space-Backend/YourSpace.Services/Services/AuthService/IAuthService.cs
Your-Space-Backend/YourSpace.WebAPI/Controllers/AuthController.cs
Your-Space-Backend/YourSpace.WebAPI.Tests/Integration/Controllers/AuthControllerTests.cs
Your-Space-Mobile/assets/translations/ar.json
Your-Space-Mobile/assets/translations/en.json
Your-Space-Mobile/lib/core/constants/api_constants.dart
Your-Space-Mobile/lib/core/router/app_router.dart
Your-Space-Mobile/lib/features/auth/data/datasources/auth_remote_data_source_impl.dart
Your-Space-Mobile/lib/features/auth/data/repositories/auth_repository_impl.dart
Your-Space-Mobile/lib/features/auth/domain/repositories/base_auth_repository.dart
Your-Space-Mobile/lib/features/home/presentation/pages/home_screen.dart
Your-Space-Mobile/test/features/home/presentation/pages/home_screen_test.dart
```

### Root cause — confirmed by inspection, NOT the sprint-1 Gender/phone work

The Gender/phone-optional conflicts resolved when merging sprint-1 do **not** recur — sprint-2 never touches `RegisterDto`, `Gender`, or the register flow. Every conflict above is a fresh **insertion-point collision**: production's independent feature commits and sprint-2's feature commits both append/insert code at the same location in a shared file, unaware of each other. Examples inspected directly:

| File | Production side (unknown to sprint-2) | sprint-2 side | Collision |
|---|---|---|---|
| `AuthService.cs` | `DeleteAccountAsync` (from `cc18cfe`) inserted right after `GetProfileAsync` | `UpdateProfileAsync` also inserted right after `GetProfileAsync` | Same insertion point, different new method |
| `api_constants.dart` | `_devBaseUrl` corrected to the real endpoint; `deleteAccount = '/auth/me'` added (from `cc18cfe`) | Still has the old ngrok dev URL; adds `profile = '/auth/me'` at the same line | Same line, both edited independently |
| `app_router.dart` / `home_screen.dart` | (unrelated production changes near the same routes block) | Onboarding + home-stats routes/screens added at the same insertion point | Same insertion point, different new routes |

This is the ordinary cost of long-lived stacked branches diverging from a moving trunk — mechanical, not architectural. None of it requires re-litigating the Gender/phone-optional decision already made and shipped in the sprint-1 merge (commit `bd2b3da` on `production`).

---

## Implication for sprint-3 and sprint-4

- **sprint-2 → production**: expect ~13 conflicting files, all mechanical (insertion-point clashes) — same class of fix as any normal merge, not a repeat of the Gender/phone work.
- **sprint-3 → production**: since sprint-3 forks from sprint-2's tip with no gap, once sprint-2 is merged and pushed, sprint-3's merge should only need to resolve conflicts against whatever *new* independent commits land on `production` between the sprint-2 merge and the sprint-3 merge — the sprint-1/sprint-2-vs-production divergence will already be resolved.
- **sprint-4 → production**: same logic — expected to be the lightest of the three, assuming no large parallel production commits land in between.

## Recommendation

Merge and release sequentially — sprint-2 → release → sprint-3 → release → sprint-4 → release — exactly as planned, verifying build + tests after each merge before moving to the next. Do not batch all three into one merge; conflicts are much easier to reason about one stack layer at a time.

## Status

**No merge has been performed for sprint-2, sprint-3, or sprint-4 yet.** This document is planning input only. See `doc/handoffs/001-sprint-branches-merge/` for full session state and next steps.
