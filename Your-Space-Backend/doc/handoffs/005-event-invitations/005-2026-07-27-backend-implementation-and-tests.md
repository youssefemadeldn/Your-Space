# Session Handoff — 2026-07-27

> **OUT OF PREVIOUS SESSION — NEW SESSION START**
>
> Read this file first. It contains everything from the prior session.

## What Was Done

- Gathered requirements (long back-and-forth, originally in Arabic) for a real problem the user has: before every family/social event, they hand-build an invitation guest list spanning several social circles (relatives, village friends, neighboring-village friends, old school friends, university friends), and there's a social reciprocity custom — if someone invited them to their event, they owe that person an invite back. Two prior tracking attempts (phone Notes app, Excel sheet) were both lost to data loss, which is why this became a real backend feature instead of a note-taking workaround.
- Created branch `feature/event-invitations` off `main`.
- Ran full Plan Mode: explored the existing backend conventions (real `AuthService`/`OtpService` code, all T1–T7/P1–P4 templates, `MockDataSeeder`, `ServiceRegistration`, `Program.cs`) via Explore + Plan subagents, wrote the implementation plan to `C:\Users\youss\.claude\plans\mossy-drifting-lampson.md`, got explicit user approval before writing any code.
- Implemented the complete "Event Guest-List / Invitation Planner" backend feature end-to-end — see **Files Changed** below. High-level shape:
  - **Person** is a shared/core entity (not owned by this feature alone) — `OwnerUserId`-scoped, soft-deletable, single-field `Name` (no `NameAr` — matches the existing `AppUser.FirstName`/`LastName` precedent, confirmed with the user).
  - **Group** is user-manageable (create/rename/delete anytime), `Name`/`NameAr` bilingual since it's a real UI label. Each `Person` belongs to exactly one `Group` (`Restrict` delete + a `GroupService.DeleteAsync` guard clause blocking deletion while active Persons still reference it).
  - **Event** is the user's own occasion being planned (soft-deletable, `Name`/`NameAr`, optional `EventDate`/`Notes`).
  - **EventGuest** is the join row tracking one person's invite status for one event: `NotInvited` / `Invited` / `Skipped`, plus the `InviteMethod` (WhatsApp/PhoneCall/Physical) chosen **live** at invite time — never fixed when the person was first entered. Hard-deletable (no soft-delete — `Skipped` already covers "excluded but tracked").
  - **PersonOccasionHistory** is the reciprocity log — independent of the user's own Events, records whether a person invited the user in the past and by what method. Optional, multi-valued per person, fully CRUD-able. Hard-deletable.
  - **UserSettings** is a lazily-created 1:1-with-`AppUser` row holding `ReciprocitySuggestionsEnabled` (default `false`) — the reciprocity-suggestions feature is off by default and the toggle is a remembered UI preference, not an access-control gate on the underlying query.
  - Six services/controllers: `GroupService`, `PersonService`, `PersonOccasionHistoryService` (nested under persons), `EventService`, `EventGuestService` (nested under events — handles bulk-add-by-person/by-group, invite/skip/revert status transitions, per-group progress summary, reciprocity suggestions), `UserSettingsService`.
  - Added the missing localization foundation (`AddLocalization`/`RequestLocalizationOptions`/`UseRequestLocalization` in `Program.cs`, `Microsoft.Extensions.Localization.Abstractions` package, `SharedResource.cs` + `SharedResource.en.resx`/`.ar.resx`) since it didn't exist yet despite CLAUDE.md Rule 8 mandating it — this feature is the first to actually use `IStringLocalizer<SharedResource>` for real.
  - One EF Core migration (`20260726202448_AddPeopleGroupsEventsFeature`), applied to the local dev Postgres DB.
  - `MockDataSeeder` extended with idempotent seed methods for all six entities (normal + edge cases: soft-deleted rows, max-length text, null-optional fields), for both seeded dev users.
- **Review round 1** (external code review, findings captured in this handoff since the review file itself no longer exists on disk — see Notes): found (a) an unused `EventGuestWithSpecs` constructor, (b) an N+1 query in `EventService.GetAllAsync` (one `CountWithSpecAsync` per event on the page instead of one batched query), (c) **zero tests written** for the new feature despite the plan's own Verification section requiring them. All three fixed:
  - Deleted the dead constructor.
  - Added `EventGuestWithSpecs.ForEvents(List<int>, ownerUserId)` and rewrote `EventService.GetAllAsync` to fetch all guest counts in one query, grouped in C#.
  - Wrote 130 tests: unit tests (Moq) for all 6 services, integration tests (real HTTP + SQLite via `TestWebApplicationFactory`) for all 6 controllers. Added `LocalizerMockFactory`, `MapperFactory`, `AuthenticatedClientExtensions` as shared test helpers. Found and fixed a real bug while writing these: the integration test JSON deserializer needed `JsonStringEnumConverter` registered client-side to match the server's actual string-enum wire format.
- **Review round 2**: flagged that the pagination count/list-pairing fix (the plan's single biggest called-out risk) had no test that could actually catch a regression — the one existing pagination test mocked the repository. Added `GroupsControllerTests.Get_all_reports_the_true_total_when_more_rows_exist_than_one_page` (seeds 15 groups over real HTTP against real SQLite, asserts `TotalItems == 15` while `Items.Count == 10`). **Verified it actually works**: temporarily reintroduced the exact bug (reused one spec instance for both `CountWithSpecAsync` and `ListAllWithSpecAsync` calls), confirmed the test failed with `TotalItems` wrongly reported as 10, then reverted.
- **Review round 3**: flagged that cross-user isolation (another user's resource → 404) was only integration-tested for `PersonsController`; the other four applicable resources relied on unit-level tests only. Independently verified this via grep before agreeing, then added the same cross-user 404 check to `GroupsController`, `PersonOccasionHistoryController`, `EventsController`, `EventGuestsController` integration tests (`UserSettingsController` doesn't need one — it has no ID param, always self-scoped from the JWT claim).
- **Final test count: 134/134 passing**, solution builds clean (0 warnings/errors).
- Ran the API locally (`dotnet run --project YourSpace.WebAPI`) against the **real Postgres dev DB** (not the SQLite test fixture) and manually verified every endpoint group via the `/hit-api` skill: logged in as the seeded `seed.active@yourspace.dev` user, confirmed all reads/writes/the `Group.HasActivePersons` guard clause/soft-delete filtering/the N+1 fix all work correctly against real data. Also confirmed — for the first time, since no automated test covers this — that the **Arabic localization pipeline works end-to-end** (`Accept-Language: ar` correctly switches both FluentValidation messages and service-level `ServiceResult` failure messages, while `ErrorCode` stays stable/untranslated). Server process was stopped cleanly afterward.
- Work is already committed and pushed to `origin/feature/event-invitations` (see Notes — this wasn't something explicitly initiated by name in the visible session).

## Bugs Found

| # | Bug | Severity | Location | Status |
|---|---|---|---|---|
| 1 | Unused `EventGuestWithSpecs(eventId, ownerUserId, personId)` constructor — dead code, never called anywhere | Low | `YourSpace.Repository/Specifications/EventSpecifications/EventGuestWithSpecs.cs` | Fixed — deleted |
| 2 | N+1 query: one `CountWithSpecAsync` per event (up to 50/page) to populate `TotalGuestCount` | Medium (perf) | `YourSpace.Services/Services/EventService/EventService.cs` `GetAllAsync` | Fixed — batched via new `EventGuestWithSpecs.ForEvents(...)` |
| 3 | Zero tests existed for the entire new feature (6 services, 6 controllers) despite the approved plan and CLAUDE.md's Testing discipline requiring them | High | `YourSpace.WebAPI.Tests/*` | Fixed — 130 tests added |
| 4 | The pagination count/list spec-pairing fix had no test that could catch a regression (existing test mocked the repo) | Medium (coverage gap) | `YourSpace.WebAPI.Tests/Integration/Controllers/GroupsControllerTests.cs` | Fixed — added + hand-verified the regression test |
| 5 | Cross-user isolation (404 for another user's resource) only integration-tested for `PersonsController`, not the other 4 applicable controllers | Medium (privacy-relevant coverage gap) | `YourSpace.WebAPI.Tests/Integration/Controllers/{Groups,PersonOccasionHistory,Events,EventGuests}ControllerTests.cs` | Fixed |
| 6 | Integration test JSON deserializer lacked `JsonStringEnumConverter`, causing 2 test failures the first time enum-bearing DTOs were deserialized client-side | Low (test-only) | `PersonOccasionHistoryControllerTests.cs`, `EventGuestsControllerTests.cs` | Fixed |

No bugs remain open.

## Files Changed

130 files changed (all additions), 6910 insertions, across the `feature/event-invitations` branch vs `main`. Grouped by layer (run `git diff main...feature/event-invitations --stat` in `Your-Space-Backend/` for the exact per-file list):

| Area | Files | Why |
|---|---|---|
| Enums | `YourSpace.Data/Enums/EventGuestStatus.cs`, `InviteMethod.cs` | New domain enums |
| Entities + Configurations | 6 entities + 6 `IEntityTypeConfiguration<T>` classes in `YourSpace.Data/Entities`/`Configurations` | Core data model |
| DbContext | `YourSpace.Data/Contexts/YourSpaceDbContext.cs` | 6 new `DbSet<T>` properties |
| Migration | `YourSpace.Data/Migrations/20260726202448_AddPeopleGroupsEventsFeature.*` + snapshot | Schema, applied to local dev DB |
| Specifications | 5 files in `YourSpace.Repository/Specifications/{GroupSpecifications,PeopleSpecifications,EventSpecifications}` | Query shapes, each with paired paged/unpaged constructors |
| Localization foundation | `SharedResource.cs`/`.en.resx`/`.ar.resx`, `Program.cs`, `YourSpace.Services.csproj` | Prerequisite plumbing that didn't exist yet (see What Was Done) |
| DTOs, Profiles, Validators | ~50 files under `YourSpace.Services/Services/{Group,Person,PersonOccasionHistory,Event,EventGuest,UserSettings}Service/` + `Validators/` | Transport contracts, AutoMapper, FluentValidation |
| Services | 6 `I<X>Service`/`<X>Service.cs` pairs | Business logic |
| Controllers | 6 files in `YourSpace.WebAPI/Controllers/` | API surface |
| Wiring | `ServiceRegistration.cs`, `MockDataSeeder.cs` | DI registration, dev seed data |
| Tests | ~50 files under `YourSpace.WebAPI.Tests/Unit/Services/*` and `Integration/Controllers/*` + 3 new shared test helpers under `Common/` | Full coverage, see What Was Done |

## Files Audited (no changes)

| File | Checked For | Result |
|---|---|---|
| `YourSpace.Services/Services/AuthService/AuthService.cs` | Primary-constructor style, `ErrorCodes` nested class pattern, `ServiceResult` usage, real `IUnitOfWork` transaction API | Matched exactly in all new services |
| `YourSpace.Data/Entities/RefreshToken.cs` + `RefreshTokenConfiguration.cs` | `AppUser` FK shape (`required string UserId` + one-directional nav + `Cascade`) | Matched exactly for every new `OwnerUserId` FK |
| `YourSpace.Repository/Specifications/{ISpecification,BaseSpecification,SpecificationEvaluator}.cs`, `GenericRepository.cs`, `UnitOfWork.cs` | Spec/repo contract, and specifically that `CountWithSpecAsync` applies the same `Skip`/`Take` as `ListAllWithSpecAsync` | Confirmed the pagination-pairing risk was real; designed around it (see Bug/Fix table) |
| `YourSpace.Repository/Specifications/Paginated/PaginationSpecification.cs`, `YourSpace.Services/Helper/PaginatedResultDto.cs` | Exact pagination shape | Reused as-is |
| `.claude/rules/dotnet_feature_prompt.md`, `CLAUDE.md`, all T1–T7/P1–P4 templates | Canonical file set, all 10 architecture rules | Followed; real-code deviations from the templates (primary constructors, singular `Configuration` naming, no `SharedResource` precedent) were identified and followed instead of the aspirational template text |
| `YourSpace.WebAPI.Tests/Common/TestWebApplicationFactory.cs`, `Integration/Controllers/AuthControllerTests.cs` | SQLite in-memory integration test setup, register→confirm→login flow | Reused pattern; factored the repeated auth flow into `AuthenticatedClientExtensions` |

## Pending Tasks

- [ ] None outstanding for the backend feature itself — all three review rounds are closed out, 134/134 tests pass, build is clean.
- [ ] **Flutter mobile client** — explicitly deferred by the user to a separate future session (not started; no Flutter code touched in this session).
- [ ] Optional/low-priority, not requested: consider whether to open a PR from `feature/event-invitations` into `main` (branch is already pushed to origin).

## What's Next (ordered)

1. If picking the backend back up: there is nothing known to be broken or missing — start by re-running `dotnet build` and `dotnet test` in `Your-Space-Backend/` to reconfirm the 134/134 green baseline, then proceed with whatever the user's next backend ask is.
2. If starting the **mobile client** session: read `Your-Space-Mobile/CLAUDE.md` and its `.claude/rules/flutter_feature_prompt.md` first (per root `CLAUDE.md`'s "never blend project rules" instruction). The mobile UI needs to cover, per the confirmed requirements in this handoff: group-by-group guest list building (add whole group / add individual persons), live invite-method choice at invite time (not baked into Person), the 3-state guest status (NotInvited/Invited/Skipped), a subtle/optional reciprocity-suggestions surface tied to the persisted `UserSettings.ReciprocitySuggestionsEnabled` toggle, and per-person occasion history CRUD. All backend DTOs/routes needed for this are enumerated in the plan file and this handoff's Files Changed section.
3. Base API URL for local testing: `http://localhost:5145` (see `YourSpace.WebAPI/Properties/launchSettings.json`); dev login credentials are the seeded `seed.active@yourspace.dev` / `Seed!Pass123` user (see `MockDataSeeder.cs`).

## Key References

- Implementation plan (approved, still on disk): `C:\Users\youss\.claude\plans\mossy-drifting-lampson.md`
- `d:\Programing\Your-Space\CLAUDE.md` — root multi-project rules
- `d:\Programing\Your-Space\Your-Space-Backend\CLAUDE.md` + `.claude\rules\dotnet_feature_prompt.md` — backend conventions this feature was built to match exactly
- `d:\Programing\Your-Space\Your-Space-Mobile\CLAUDE.md` — read this first when the mobile session starts

## Clarifications & Decisions

| Question | Answer |
|---|---|
| Should this guest-list feature be part of the existing Your Space app, or standalone? | Part of Your Space App; focus only on the backend now — mobile client will be a separate future session |
| Should groups (relatives, village friends, etc.) be a fixed set or user-manageable? | User-manageable — user can create/rename/delete groups anytime |
| Can one person belong to more than one group? | No — exactly one group per person |
| Should the system auto-flag/suggest people who've invited the user before ("reciprocity"), or stay purely manual? | Merge both: off by default, revealed via a small subtle toggle/button (not an automatic gate on the query itself) |
| Should the reciprocity on/off preference be persisted server-side, or purely an on-demand/client-side thing? | Persist it per user, for consistency across sessions/devices |
| For per-event guest status, 2 states (Not Invited/Invited) or 3 (add "Skipped")? | 3 states — Not Invited / Invited / Skipped, so a person can be excluded from one event while staying in the master list |
| Should every Person/Group/Event be private per logged-in user, or ever shared across users? | Private per user — no sharing |
| Branch name for this work? | `feature/event-invitations` |
| Should `Person.Name` and other personal free-text fields (occasion notes) get a bilingual `NameAr`/`NotesAr` sibling, or stay single-field like `AppUser.FirstName`/`LastName` already does? | Single-field (recommended option) — only `Group.Name`/`Event.Name` (genuine UI labels) get the `Ar` sibling |
| (Mid-session, not a question but an explicit correction) Should the invite method (WhatsApp/call/physical) be fixed when a Person is first entered into the system? | No — it's chosen live, at the moment of actually inviting them for a specific event; entering a Person never records a method. The only place a method is recorded at entry time is optionally, for *past* reciprocity history (did they invite me, and how) |
| (Mid-session instruction) Is it OK to test the new endpoints via a running local server / curl before being asked? | No — explicitly told not to hit the API until asked. (Later in the session the user did explicitly ask, via `/hit-api`, and that was carried out.) |

## Notes

- **The `doc/reviews/001-2026-07-26-event-invitations-feature-review.md` file referenced during round 1 no longer exists on disk** (`doc/reviews/` is currently empty) — its findings are fully captured in this handoff's "Bugs Found" table instead, so nothing is lost, but don't expect to find that file if you go looking for it.
- **The branch is already committed and pushed** to `origin/feature/event-invitations` — two commits (`feat: Implement Event Guest-List / Invitation Planner feature`, `Add unit tests for Person and UserSettings services`). This happened outside of an explicit `git commit`/`git push` request in the visible session (likely a hook, or the user acting in parallel) — worth confirming with the user directly if a new session needs to know exactly how/when that happened, rather than assuming.
- The root `CLAUDE.md`'s project table lists paths as `.net/` and `flutter/`, but the actual folder names in this repo are `Your-Space-Backend/` and `Your-Space-Mobile/` — a pre-existing minor doc/reality mismatch, not something introduced this session.
- Real-codebase conventions were deliberately followed over the aspirational template docs in a few places worth remembering for future features in this backend: primary-constructor service classes (not classic constructor-body field assignment), singular `<Entity>Configuration` naming (not the templates' plural `<Entity>Configurations`), and `ClaimTypes.NameIdentifier` for the current-user claim (not the templates' `"uid"`).
- `EventGuest`/`PersonOccasionHistory` are intentionally hard-deletable (no `DeletedAt`) — they're join/log rows, distinct from `Group`/`Person`/`Event` which are soft-deletable master data the user must never lose (directly tied to the original problem: two prior guest-list tracking attempts were lost to data loss).
