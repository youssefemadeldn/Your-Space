# Epic 001 — Post-Launch Feedback (consolidated handoff)

> Single compacted record of the whole `001-post-launch-feedback` epic. Replaces the 10 separate
> files that used to live in `doc/handoffs/001-post-launch-feedback/` (audit, plan, 3 feature specs,
> and 6 session handoffs). **All 4 sprints are implemented, tested, and committed on
> `sprint-4/post-launch-feedback`; nothing is merged to `main`. Only real device/simulator
> verification and the merge decision remain — both the user's own task.**

---

## 1. Origin

After using **Your Space** (personal relationship / gift-giving / event-invitation planner) in daily
life, the app owner raised **10 post-launch items** (1 confirmed bug + 9 UX/feature requests). These
were audited against real source (every claim file-path-backed, zero assumptions), resolved through
interactive `AskUserQuestion` rounds, then sequenced into a 4-sprint plan. Two additional features
(Location Hierarchy, Relationship Engine) were speced the following day and folded into the plan.

**Housekeeping drift (still unfixed, non-blocking):** root `CLAUDE.md` documents the projects at
`.net/` and `flutter/`; the real folders are `Your-Space-Backend/` and `Your-Space-Mobile/`.

**Working-style notes carried across every session:** user writes prompts in Arabic, wants replies in
English; strongly prefers `AskUserQuestion` (with a recommended option + reasoning per choice) over
open-ended text questions; "no assumptions" — verify against real files, don't guess.

---

## 2. The 10 items — final decisions

| # | Item | Final decision |
|---|---|---|
| 1 | Settings screen / logout / AppBar | Settings = **5th bottom-nav tab** (Edit profile + Logout; profile photo added in Sprint 3). Remove `AppAppBar` **only from the 4 main tab screens** (Home/Groups/People/Events); detail/form/edit screens keep it for back-nav + title. |
| 2 | "Add group" loading-indicator bug | `AddGuestsActionSubmitting` carries the specific `groupId`/`personIds`; **all 3** sharing buttons (by-group rows, People-tab "Add N people", Reciprocity "add as guest") check identity before showing `loading:true`. |
| 3 | "Real navigation bar" | A working 4-tab bottom nav already existed. Real need: **preserve tab state** across switches (`IndexedStack`) + add the 5th Settings tab. |
| 4 | Splash screen | **Native** splash via `flutter_native_splash`, assets `doc/design/assets/splash_logo.png` + `splash_logo_android12.png`, bg `#FAFAFA`, no dark variant. Dead `kSplashDuration` removed. |
| 5 | 3 onboarding screens | Shown **once on first launch**, gated by `shared_preferences` flag. Copy drafted (headline + body per screen) — see §3. |
| 6 | Person photo + Cloudflare | **R2** (S3-compatible, `AWSSDK.S3`), not Cloudflare Images. Two buckets, same account: `your-space-users-avatars` (user avatar, single photo) and `our-space-people-photos` (Person photos, up to 6, one `IsPrimary`). **Private / presigned URLs (24h, configurable).** Upload-only (no "paste a link"). JPEG/PNG only, ~5MB cap. No face-detection. Picker inline in the Person form. |
| 7 | Optional subgroup | Real managed entity (own CRUD, like `Group`), scoped to exactly one parent `Group`. Changing a person's `GroupId` **auto-clears** `SubGroupId`. Bulk "add guests by subgroup" added. Subgroup filter added to People/Group screens. |
| 8 | Second phone number | Exactly 2 (`PhoneNumber` + `PhoneNumber2`), unlabeled, same `^\+?[1-9]\d{7,14}$` validation on both. |
| 9 | Note field on person | Single free-text `Notes`, max **2000 chars**. Editable anytime from the form. Shown on **Person Details only**, not list views. |
| 10 | Gender field | **Superseded by the Relationship Engine:** `Gender` is now **required**, **Male/Female only** (no "Prefer not to say"), on **both** registration (`AppUser`) and `Person`. Plain `int` storage (no `HasConversion`), `defaultValue: 0` on migration. Metadata only beyond driving relationship-inverse derivation. |

---

## 3. Onboarding copy (used verbatim in Sprint 2)

| # | Headline | Body |
|---|---|---|
| 1 | Your People, Organized | Keep every friend, family member, and contact organized into groups — and now subgroups — so you always know who's who, right when you need them. |
| 2 | Plan Events Without the Chaos | Create an event, add guests one by one or invite a whole group at once, and track exactly who's invited, who's still pending, and who you've decided to skip. |
| 3 | Never Forget Who Invited You | Your Space quietly tracks who's invited you to their own occasions — so when it's time to plan your next event, you'll know exactly who to invite back. |

---

## 4. Feature spec — Location Hierarchy (2026-08-05)

A 3-level location axis on `Person`, **fully independent** of `Group`/`Subgroup` (no FK link either
direction; "above Group" only meant "picked first in the flow").

| Level | Meaning | Required? | Storage |
|---|---|---|---|
| 1 — Governorate | Egypt's 27 governorates | **Required** (`Person.GovernorateId`) | **Global + seeded + lockable, but user-extensible**: nullable `OwnerUserId` (null = global/seeded) + `IsLocked bool`. A genuinely new pattern — everything else in the codebase is strictly per-user. |
| 2 — City | City/town within a governorate | Optional (`Person.CityId`) | Real managed entity, own CRUD, user-created only (**not** pre-seeded). Scoped to parent Governorate. |
| 3 — Neighborhood (حي/منطقة) | Area within a city | Optional (`Person.NeighborhoodId`) | Real managed entity, own CRUD, user-created. Scoped to parent City. |

`CityId` validated server-side against `GovernorateId`; `NeighborhoodId` against `CityId`. Bulk-add
event guests by governorate/city/neighborhood + location filters on People/Group screens (full parity
with Subgroup). No migration/backfill concern — test DB, reset freely.

---

## 5. Feature spec — Relationship Engine (2026-08-05)

Person-to-person kinship graph, scoped entirely within one user's own People.

**Entity `PersonRelationship`:** `Id`, `PersonId` (whose profile the relation is on),
`RelatedPersonId`, `RelationType`, `CreatedAt`, `InverseRelationshipId` (explicit link to the
auto-derived inverse row — used for cascade-delete, since two rows can legitimately share the same
`(PersonId, RelatedPersonId)` pair with different types). Both persons must share `OwnerUserId`.

**Enum `RelationType` — 14 fixed values:** Husband, Wife, Father, Mother, UncleMaternal, AuntMaternal,
UnclePaternal, AuntPaternal, Son, Daughter, Brother, Sister, Nephew, Niece. (Nephew/Niece added after
catching that Uncle/Aunt had no inverse.)

**Auto-derived inverse** (`RelationInverseResolver`, static lookup) is a function of the original
relation type **and the subject's own gender** — which is exactly why Gender became required/binary
(item 10). Father/Mother→Son/Daughter; Son/Daughter→Father/Mother; Brother/Sister→Brother/Sister;
Husband↔Wife; Uncle/Aunt(any)→Nephew/Niece; Nephew/Niece→Uncle/Aunt (**known limitation:** loses the
Maternal/Paternal distinction on this one reverse direction — defaults to Paternal). Deleting a
relationship cascade-deletes its inverse row.

**Validation:** no self-link; max 1 incoming Father + 1 incoming Mother per person; no circular
parent/child chains (in-memory BFS); **unlimited spouses** (Egyptian family law).

**UI:** Step 3 of the Person wizard — a repeater of `[Relation Type dropdown] + [searchable Person
lookup, unrestricted across all the user's People] + [remove row]`.

---

## 6. The 4-sprint plan

Sequenced by dependency/effort, not report order. Backend = `Your-Space-Backend/`, Mobile =
`Your-Space-Mobile/`; each project stays governed by its own `CLAUDE.md`.

| Sprint | Scope | Touches |
|---|---|---|
| **1 — Quick wins** (no deps) | #2 loading bug, #4 splash, #8 phone 2, #9 notes, #10 gender | Backend (#8/#9/#10) + Mobile (all 5) |
| **2 — Nav shell** | #3 tab-state preservation (`IndexedStack`), #1 Settings tab + AppBar removal, #5 onboarding | Mobile (+ a small backend `PUT /auth/me` added mid-sprint) |
| **3 — Photos + R2** | R2 storage service, avatar endpoints, `PersonImage` endpoints (backend); `image_picker` + Settings avatar picker (mobile). **Does not** build the Person multi-photo picker — that's Sprint 4's wizard Step 1. | Backend + Mobile |
| **4 — Person classification** | Subgroup + Location hierarchy + Relationship Engine + the 4-step Person wizard | Backend + Mobile |

Sprints 3 & 4 were swapped from the original order (Photos before the wizard) so the wizard's Step 1
photo picker is built once against endpoints that already exist. Sprint 4 depends on Sprint 1's
required/binary Gender.

**Design mockups (done 2026-08-06)** live in
`Your-Space-Mobile/doc/design/_ds/your-space-design-system-d7e9f78e-54b1-42d1-8d71-9921cb11ec65/ui_kits/app/`:
`new-screens.html` (index), `settings.html`, `person-wizard.html` (full 4-step), `subgroup-management.html`,
`city-management.html`, `neighborhood-management.html`. The 4 original screen mockups (Home/People/
Event detail/Create event) are compiled into `_ds_bundle.js` as JSX text, not standalone HTML.

---

## 7. Sprint 1 — implemented (2026-08-06)

First real code in the epic. Branch `sprint-1/post-launch-feedback` off `main`.

- **Backend (~135 files with mobile):** new `Gender` enum; `Person` gains `PhoneNumber2`/`Notes`/`Gender`,
  `AppUser` gains `Gender`; migration `20260806090851_AddPersonPhoneNumber2NotesAndGenderFields`
  (applied to local Postgres, `defaultValue:0` on both tables); DTOs/validators/services/seeders
  threaded through; `RegisterDtoValidator` got `IStringLocalizer` **only** for the new Gender rule
  (its 6 pre-existing hardcoded-English rules left untouched, flagged).
- **Mobile:** item 2 loading-bug fix (all 3 buttons); `flutter_native_splash` wired, `kSplashDuration`
  removed; new `core/entities/gender.dart` + `core/widgets/gender_chip_group.dart`; 3 new fields
  threaded end-to-end through the Person + Auth chains; `register_screen.dart` split into a folder
  (was 249 lines, 1 under Mobile Rule 6's threshold before Gender). Gender **not** shown on Person
  Details — flagged fast-follow.
- **Verified:** backend `dotnet build` 0 err, 118/118 unit tests, live HTTP smoke test clean.
  Mobile `flutter analyze` 0, 169/169 tests.
- Plan file: `C:\Users\youss\.claude\plans\nested-gathering-walrus.md`.

---

## 8. Sprint 2 — implemented (2026-08-06)

Branch `sprint-2/post-launch-feedback` off `sprint-1/...` (not `main`).

- **Backend (~38 files with mobile):** new `UpdateProfileDto` + validator, `AuthService.UpdateProfileAsync`,
  `PUT /auth/me` `[Authorize]` endpoint (First/Last name + Phone only; Gender + Email stay locked).
- **Mobile:** shell converted to `StatefulShellRoute.indexedStack` (Home/Groups/People/Events/Settings
  branches; all other routes stay top-level `GoRoute` siblings); `AppBottomNav` 5th item; AppBar +
  per-screen `bottomNavigationBar` removed from the 4 main screens; Home gets avatar + time-of-day
  greeting + static non-functional notification bell; Groups/People/Events get in-body headline
  titles; new `lib/features/settings/` (Logout moved here from Home); new `lib/features/onboarding/`
  (3 screens, `shared_preferences` gate via new `AppPreferencesHelper`, checked first in
  `resolveSplashRedirect`); `AppListTile` gained optional `iconColor`/`titleColor` for the red Logout row.
- **2 bugs caught + fixed same-session:** a `static` test field on `AuthService_UpdateProfileAsyncTests`
  that would leak mutated state; onboarding icon-circle vertical overflow at short viewport (wrapped in
  `LayoutBuilder` + `ConstrainedBox` + `SingleChildScrollView`).
- **Verified:** backend 119/119 unit tests; mobile `flutter analyze` 0, 176/176 tests.
- Plan file: `C:\Users\youss\.claude\plans\sorted-wandering-crayon.md`.

---

## 9. Sprint 3 — implemented (2026-08-07) + stale-tab-data bug fix (2026-08-08)

Branch `sprint-3/post-launch-feedback`.

### Part 1 — Photos + Cloudflare R2 (complete, live-verified, closed)

- **Backend (~30 files):** new `StorageService/` (`IR2StorageService`, `R2StorageService`, `R2Settings`)
  + `StorageServiceExtension`; new `PersonImage` entity + `PersonImageConfiguration` (partial unique
  index = one primary per person) + migration `20260807000419_AddPersonImagesAndUserAvatar`
  (`AppUser.AvatarObjectKey` column too); `PersonImageService` (max-6 cap, first-upload auto-primary,
  delete-of-primary promotes next, transaction-wrapped); `AuthService` gains
  `UploadAvatarAsync`/`RemoveAvatarAsync` (`BuildProfile` became instance-async to resolve
  `AvatarUrl`); `POST/DELETE /auth/me/avatar` + new `PersonImagesController` (`/persons/{id}/images`,
  mirrors `PersonOccasionHistoryController`); `FakeR2StorageService` for tests.
- **Mobile (~20 files):** `image_picker: ^1.2.3` + iOS/Android permissions; `avatarUrl` through the
  Auth chain (multipart via `dio.FormData`); `ProfileFormCubit` gains
  `ProfileFormAvatarUploading/Success/Error` states (deliberately independent of
  `ProfileFormSubmitting` — Sprint 1's isolated-loading lesson); `settings_screen/` folder +
  `settings_avatar_section.dart`; `AppAvatar` gains `photoUrl` (`CachedNetworkImage`, initials
  fallback); Home header avatar shows the real photo too.
- **Two real R2 bugs found + fixed via live smoke test:** (1) AWSSDK.S3 v4's streaming/chunked SigV4
  payload signing isn't implemented by R2 → `RequestChecksumCalculation.WHEN_REQUIRED` /
  `ResponseChecksumValidation.WHEN_REQUIRED` on `AmazonS3Config`, `UseChunkEncoding=false` /
  `DisablePayloadSigning=true` on `PutObjectRequest` (safe — R2 is always HTTPS). (2) "Access Denied" —
  the R2 API token was scoped to an unrelated project's bucket (`vetlink-products`); user created a
  new token scoped to the two Your Space buckets, updated in `dotnet user-secrets`.
- **Verified:** backend 141/141 unit tests; mobile `flutter analyze` 0, 182/182 tests; full live
  smoke test against the real R2 account (upload/download/byte-compare/remove on both buckets);
  **user did the in-app 10-point visual check themselves — reported clean.**
- Plan file: `C:\Users\youss\.claude\plans\kind-meandering-music.md`.
- **Decisions:** R2 creds in `dotnet user-secrets` only, never committed; presigned expiry 24h
  (`R2Settings.PresignedUrlExpiryHours`); Home avatar shows the real photo (reverses `AppAvatar`'s
  prior "no real photos" stance).

### Part 2 — Stale tab/list data bug (`DataRefreshBus`) — implemented, unit-tested, in-app verification pending

- **Symptom:** after any mutation (photo upload, add person/event, etc.) the change wasn't visible
  until logout→login.
- **Root cause** (`lib/core/router/app_router.dart:147-220`): the Sprint 2 `StatefulShellRoute.indexedStack`
  branches each create their cubit once with `..load()`; `IndexedStack` never rebuilds a visited
  branch, so mutations elsewhere never reach an already-built tab's cubit. Also one level deeper —
  `EventDetailsCubit`/`PersonDetailsCubit` are pushed routes kept alive underneath a further push.
  (Technically a Sprint 2 regression.)
- **Rejected fix:** watch `navigationShell.currentIndex` and refresh on tab switch — misses the
  dominant push-form → save → pop-back-to-same-tab flow (index never changes), and refetches
  unconditionally on every tab tap.
- **Built:** `lib/core/events/data_refresh_bus.dart` — `@lazySingleton DataRefreshBus` (broadcast
  `StreamController`) keyed by `DataScope` enum with **5 values**: `people`, `groups`, `events`,
  `eventGuests`, `profile`. `eventGuests` kept separate from `events` so `HomeStatsCubit` (events
  *count* only) doesn't refetch on every guest-status flip. **Constructor injection** (last param) into
  all 12 touched cubits — 6 notifiers (`PersonFormCubit`, `GroupActionCubit`, `EventFormCubit`,
  `EventGuestActionCubit`, `AddGuestsActionCubit`, `ProfileFormCubit`) call `.notify(scope)` on
  success; 6 subscribers (`HomeStatsCubit`, `PeopleListCubit`, `GroupsListCubit`, `EventsListCubit`,
  `PersonDetailsCubit`, `EventDetailsCubit`) subscribe in the constructor, cancel in `close()`, and
  expose a **silent `refresh()`** (guarded on `state is XSuccess`, preserves filters/search, never
  emits `Loading`). `PeopleListCubit` also got `refreshGroups()` for its embedded group-filter
  dropdown. Failed background refresh keeps the last-good list (no error screen).
  `RefreshIndicator` pull-to-refresh added to `people_list_body.dart`, `groups_list_body.dart`,
  `events_screen.dart` — `onRefresh` calls the same silent `refresh()`.
- **Rejected alternative:** making list cubits `@lazySingleton` — violates the project's factory-scoping
  DI rule for cubits. Do not revisit without a strong new reason. (Note: `CartCubit` referenced in
  `Your-Space-Mobile/CLAUDE.md`'s DI table is a documented *pattern*, not an actual class here.)
- **Verified:** `flutter analyze` 0, `flutter test` **203/203** (per-cubit bug-repro tests). **Real
  in-app verification still the user's task** — no iOS simulator on the implementing machine.
- Plan file: `C:\Users\youss\.claude\plans\read-the-doc-handoffs-001-post-launch-fe-delegated-flute.md`.

---

## 10. Sprint 4 — implemented + committed (2026-08-08)

Subgroup + Location Hierarchy + Relationship Engine + 4-step Person wizard. Planned via `/clarify-loop`
+ Plan sub-agent. Shipped as **one pass** (not 4a/4b/4c).

**Branch `sprint-4/post-launch-feedback`, 3 commits on top of `3f9fd62`** (which is the standalone
`DataRefreshBus` commit — Sprint 3 Part 2, committed first at the start of this session):

| Commit | Scope | Stat |
|---|---|---|
| `65e21c1` | Backend feature — entities/configs/specs/services/controllers/DI/localization/seeding for all 5 new areas + `Person`/`EventGuestService` extensions + ~20 ripple-fixed test files | ~50 files |
| `5a6720f` | Mobile feature — wizard, `classification` module, filters, Add Guests tabs, avatar wiring, ~145 translation keys, ripple fixes | 124 files, +7291/-716 |
| `8d8e1ed` | Backend tests — 24 new unit test files for the 5 new services + `RelationInverseResolver` `[Theory]` over all 28 type×gender combos | 24 files, +1694 |

### Backend

- New entities with full file sets mirroring `Group`'s shape: `SubGroup` (under `Group`),
  `Governorate`/`City`/`Neighborhood`, `PersonRelationship`.
- `Governorate` = nullable `OwnerUserId` + `IsLocked bool` (new pattern, no precedent).
- `PersonRelationship`: 14-value enum, `RelationInverseResolver` static lookup, validation (no
  self-link, max 1 Father + 1 Mother, no circular chains via in-memory BFS, unlimited spouses),
  cascade-delete via stored `InverseRelationshipId`.
- `Person` gains `SubGroupId` / `GovernorateId` (required) / `CityId` / `NeighborhoodId`. Auto-clears
  `SubGroupId` on `GroupId` change; **validate-and-reject** (not auto-clear) for location-field
  inconsistency — asymmetric by design. Primary `PersonImage` URL resolution added to `PersonService`.
- 4 new bulk-add endpoints on `EventGuestsController` (`by-subgroup`/`by-governorate`/`by-city`/
  `by-neighborhood`), all reusing the existing private `AddGuestsAsync` helper.
- **Bug fixed:** `Program.cs` ran `MockDataSeeder.SeedAsync` before `IdentitySeeder.SeedAsync` —
  broke first boot on a fresh DB (`MockDataSeeder` needs the "User" role). Reordered.
- Migration forced **dropping + recreating the local dev Postgres DB** (`GovernorateId` going
  required has no backfill) — user approved explicitly. DB now has all 27 Egyptian governorates
  seeded; prior sprints' smoke-test artifacts are gone.
- **Verified:** `dotnet build` 0 err, **226/226 unit tests** (139 pre-existing + 87 new), live boot +
  seed clean. Integration tests blocked by a pre-existing `e_sqlite3` Windows Application Control
  policy issue on this machine — not a regression.

### Mobile

- Flat Person form → **4-step wizard** (`person_wizard_screen/`): (1) Basic Identity + staged photo
  grid (up to 6, tap-to-primary, **nothing uploads until final Save** for both Add and Edit; Edit
  pre-seeds from `GET /persons/{id}/images`); (2) Group→Subgroup + Governorate→City→Neighborhood
  cascading pickers (new `AppCascadingSelect`, inline "+ Add new"); (3) relationship repeater with
  person-search autocomplete; (4) notes. Submit diffs staged photos/relationships against the loaded
  baseline; partial photo/relationship failure surfaces as a non-blocking warning, Person is never
  rolled back client-side.
- Deleted `person_form_screen.dart` / `person_form_cubit/` entirely; fixed all call sites.
- New `classification` feature module: `SubGroup`/`Governorate`/`City`/`Neighborhood` data+domain
  layers, **3 separate dedicated cubit pairs** (list+action) — user explicitly overrode the
  recommended generic-cubit design, citing the one-cubit-per-concern convention; the 3 management
  screens still share one presentational body widget.
- People list avatar + Person Details header show the primary photo. Groups screen: "Manage
  subgroups" per-row entry point. People screen: 5-dimension filter sheet (group/subgroup/governorate/
  city/neighborhood) — `PeopleListCubit` got a `_refetch` helper so the 5-filter call exists once.
- Add Guests: 4 new tabs. **Design gap resolved:** only Governorate has a flat "all of mine"
  endpoint — Subgroup/City/Neighborhood tabs each cascade through their own parent picker first.
  `AppTabs` modified to scroll horizontally past 3 tabs (≤3-tab callers unchanged).
- `DataScope.classification` (new enum value) wired through `PeopleListCubit`/`AddGuestsListCubit`.
- **Bug fixed:** `PersonWizardCubit` joined partial-failure translation *keys* then called `.tr()`
  once on the joined string — can't resolve. Fixed by carrying `partialFailureKeys: List<String>?`
  and translating per-key at display.
- **Verified:** `flutter analyze` 0, `dart run build_runner build` clean, `flutter test` **199/199**.
- Plan file: `C:\Users\youss\.claude\plans\plan-for-sprint-4-silly-raven.md`.

---

## 11. Current state / what's left

**All 4 sprints + the `DataRefreshBus` regression fix are implementation-complete and automated-tested.**
Branch chain: `main` → `sprint-1/...` → `sprint-2/...` → `sprint-3/...` (Sprints 1–3 + `DataRefreshBus`)
→ `3f9fd62` (`DataRefreshBus` as its own commit) → `sprint-4/post-launch-feedback` (`65e21c1`, `5a6720f`,
`8d8e1ed`). **Nothing is merged to `main`.**

Open — all the user's own tasks per this epic's established pattern:

- [ ] **Real in-app / device verification** — no simulator was ever available in the implementing
  sessions. Covers: full 4-step wizard end-to-end (inline "+ Add new", photos, relationships) →
  Person Details; Edit-mode round-trip of staged photos/relationships; primary photo on list +
  details; 3 management screens' CRUD incl. delete-with-children conflict; 4 new Add-Guests tabs +
  their parent-picker cascades; People filter sheet (5 dims + cascade resets); Governorate inline
  "+ Add new" propagating via `DataScope.classification`; the `DataRefreshBus` scenarios
  (push form → save → pop back to same tab → list updates without tab switch / logout); pull-to-refresh
  on People/Groups/Events; native splash on a real device; Register + Person form with Gender;
  RTL/Arabic spot-check (~145 new keys in Sprint 4 alone).
- [ ] **Merge decision** for `sprint-4/post-launch-feedback` → `main` — closes out the whole epic.
- [ ] Decide whether the `DataRefreshBus` fix ships bundled with "Sprint 3" or as its own labeled change.
- [ ] Add Gender display to Person Details (flagged fast-follow from Sprint 1, never requested).
- [ ] Pre-existing backend integration-test gap: `PendingModelChangesWarning` at host startup
  (`TestWebApplicationFactory` uses SQLite `EnsureCreated()` while `Program.cs` runs
  `MigrateAsync()` against Postgres-targeted migrations) — later compounded/replaced on this machine
  by an `e_sqlite3` Windows Application Control policy block. Unrelated to any sprint; unfixed.
- [ ] No Sprint 5 exists — further work needs its own new plan/handoff folder.

---

## 12. Key references

- **Master plan:** `feedback-plan-2026-08-04.md` content is folded into §6 above (original file deleted).
- **Approved plan files** (still on disk, richest per-file design detail):
  - `C:\Users\youss\.claude\plans\nested-gathering-walrus.md` — Sprint 1
  - `C:\Users\youss\.claude\plans\sorted-wandering-crayon.md` — Sprint 2
  - `C:\Users\youss\.claude\plans\kind-meandering-music.md` — Sprint 3 Part 1
  - `C:\Users\youss\.claude\plans\read-the-doc-handoffs-001-post-launch-fe-delegated-flute.md` — `DataRefreshBus`
  - `C:\Users\youss\.claude\plans\plan-for-sprint-4-silly-raven.md` — Sprint 4
- **Design system:** `Your-Space-Mobile/doc/design/_ds/your-space-design-system-d7e9f78e-54b1-42d1-8d71-9921cb11ec65/`
  — `ui_kits/app/new-screens.html` (index of the 5 new mockups); original 4 screens live as JSX in `_ds_bundle.js`.
- **Per-project rules:** `Your-Space-Backend/CLAUDE.md`, `Your-Space-Mobile/CLAUDE.md` — respected throughout.
- **Pre-existing context briefs:** `doc/context/project-status.md`, `doc/context/next-feature-status.md`.

### Security / credentials

Live Cloudflare R2 credentials were pasted into chat transcripts during Sprints 1 and 3. They must
**never** be written to any git-tracked file (`appsettings.json` etc.) — the currently-active,
correctly-scoped R2 API token's `AccessKey`/`SecretKey` are set in local `dotnet user-secrets`
(`R2:AccessKey`, `R2:SecretKey`) and need nothing further unless something changes on the Cloudflare
side. `appsettings.json` holds only a shape-only `R2` section.

### Dev-environment notes

- `dotnet-ef` global tool was upgraded `10.0.6` → `10.0.10` (permanent, machine-global).
- Transient Windows Defender/AV `.git/objects` "Permission denied" errors during commit are a known
  harmless issue — retry; commit integrity was verified byte-for-byte each time.
- If `dotnet build` fails with `MSB3027`/`MSB3021` file-lock, kill a lingering `YourSpace.WebAPI.exe`
  first (`Stop-Process -Name "YourSpace.WebAPI" -Force`).
- `api_constants.dart`'s `_devBaseUrl` is a rotating ngrok URL — expected to change across sessions,
  not a code issue.
