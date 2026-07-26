# Review: Event Guest-List / Invitation Planner backend feature

**Date:** 2026-07-26
**Branch:** `feature/event-invitations`
**Plan reviewed against:** `mossy-drifting-lampson.md` (Event Guest-List / Invitation Planner — Backend Feature Plan)
**Scope:** 6 entities (`Group`, `Person`, `Event`, `EventGuest`, `PersonOccasionHistory`, `UserSettings`), 6 services/controllers, specifications, validators, one EF Core migration, `en`/`ar` localization resources, `MockDataSeeder` additions, and the foundational localization plumbing (`AddLocalization`/`RequestLocalizationOptions`).

**Method:** read every new/modified file against the plan and against `CLAUDE.md` + `.claude/rules/dotnet_feature_prompt.md`; ran `dotnet build` (0 warnings/errors) and `dotnet test --filter FullyQualifiedName~Architecture` (2/2 passed — layer boundaries and DTO/entity separation both hold).

---

## Overall verdict

Unusually faithful execution of the plan. Every entity, configuration, delete-behavior choice, specification pairing, service guard clause, validator, controller route, and localization key matches what was planned — including subtle details the plan explicitly called out as easy to get wrong.

Specifically verified correct:

- **Entities/configurations** — all 6 entities match field-for-field. FK delete behavior is exactly as specified: `Restrict` on `Person.GroupId → Group` (paired with the `GroupService.DeleteAsync` → `Group.HasActivePersons` guard clause), `Cascade` everywhere else. Soft-delete (`DeletedAt`) only on `Group`/`Person`/`Event`; `EventGuest`/`PersonOccasionHistory` are correctly hard-deletable log/join rows.
- **Localization** — `AddLocalization()` + `RequestLocalizationOptions` (default `en`, supported `en`/`ar`) wired in `Program.cs`; `UseRequestLocalization()` placed in the exact pipeline position specified (after CORS, before `ExceptionMiddleware`). Both `SharedResource.en.resx` and `SharedResource.ar.resx` contain every key from the plan's §6, in matching pairs. `LocalizedTextResolver` used consistently everywhere a `Name`/`NameAr` pair needs resolving to one client-facing field.
- **Pagination count/list pairing** — the plan flagged a real correctness trap: reusing one paginated spec instance for both `CountWithSpecAsync` and `ListAllWithSpecAsync` silently caps the count to page size. Every specification (`GroupWithSpecs`, `PersonWithSpecs`, `EventWithSpecs`, `EventGuestWithSpecs`, `PersonOccasionHistoryWithSpecs`) correctly ships separate paged/unpaged constructor overloads sharing one predicate builder. No instance of the bug anywhere.
- **Response envelope / Rule 10** — every `ServiceResult` failure carries a matching `ErrorCode` from the same localizer key used for `Message`. Every mutating DTO has a validator. Every controller carries a class-level `[Authorize]` — stricter than the plan's own route table, which only annotated mutating verbs; the shipped code protects GET actions too, which is the more correct posture.
- **`PersonOccasionHistoryService.UpdateAsync`** — correctly resolves `InviteMethod`-nulling against the *merged post-update* state (`dto.InvitedMe ?? entry.InvitedMe`), not just the request DTO in isolation. This was called out in the plan as a subtlety a validator alone can't see, and it's handled right.
- **A genuine improvement over the plan**: `EventGuestService.GetProgressAsync` calls `new PersonWithSpecs(ownerUserId, (int?)null, (string?)null)` with explicit casts — this resolves a real C# overload-resolution ambiguity between two 3-argument `PersonWithSpecs` constructors that would otherwise not compile with bare `null, null`. Deliberate and correct.
- **`MockDataSeeder`** — idempotent (existence check per method), seeds a second "locked" user for cross-user isolation testing, includes soft-deleted/max-length/null-optional-field edge cases per entity, and 15 Bogus-generated `Person` rows (plus edge cases) to exercise pagination. Seeding runs strictly inside `IsDevelopment()`, after `Database.Migrate()`, matching Rule 9 exactly.
- **Build & architecture tests** — `dotnet build` succeeds solution-wide with 0 warnings/errors. `ArchitectureLayeringTests` (layer-direction + DTO/entity-separation, generic across the whole `Dtos` namespace pattern so it automatically covers the new feature) passes 2/2 without modification.

---

## Findings

### 1. No tests were written for this feature (most significant gap)

The plan's own "Verification" section calls for:

> `dotnet test` — new `Unit/Services/<Feature>Service/<Feature>Service_<Method>Tests.cs` per service method (ownership scoping, not-found-for-other-user's-resource, the `Group.HasActivePersons` guard, the `InviteMethod` forced-null-on-`InvitedMe=false` rule, the count-vs-list paginated-spec-pair correctness) + `Integration/Controllers/<Feature>ControllerTests.cs` via `WebApplicationFactory` for at least the happy path and the `[Authorize]` rejection path per controller.

CLAUDE.md's Testing discipline section and the feature prompt's Pre-Ship Checklist mandate the same. Right now `YourSpace.WebAPI.Tests` contains zero test files for any of the six new services or controllers — every existing test still belongs to the pre-existing `AuthService`/`OtpService`/`AuthController`. This is the one place the implementation diverges from both the plan and the project's standing rules.

**Recommendation:** add `Unit/Services/<Feature>Service/...Tests.cs` per service (prioritize `GroupService` for the `HasActivePersons` guard, `PersonOccasionHistoryService` for the merged-state `InviteMethod` rule, and the paginated-spec count/list pairing) and `Integration/Controllers/...ControllerTests.cs` per controller for the happy path + `[Authorize]` rejection.

### 2. Dead code: unused `EventGuestWithSpecs` constructor

`YourSpace.Repository/Specifications/EventSpecifications/EventGuestWithSpecs.cs:16`:

```csharp
// Duplicate-add check for one (event, person) pair
public EventGuestWithSpecs(int eventId, string ownerUserId, int personId)
    : base(eg => eg.EventId == eventId && eg.Event.OwnerUserId == ownerUserId && eg.PersonId == personId)
{
}
```

This constructor — called for explicitly in the plan ("by (eventId, owner, personId) for duplicate-add checks") — is never actually invoked anywhere in the codebase. `EventGuestService.AddGuestsAsync` took a better approach instead: it fetches *all* existing guests for the event once via `EventGuestWithSpecs.ForEvent(...)` and diffs the requested IDs against that set in memory, which made the per-pair constructor redundant (confirmed via a full-repo grep for `new EventGuestWithSpecs(` — only the count/list/`ById`/`ForEvent` shapes are ever called).

**Recommendation:** delete this constructor.

### 3. Minor N+1 query in `EventService.GetAllAsync`

`YourSpace.Services/Services/EventService/EventService.cs:57-64`:

```csharp
var guestRepo = unitOfWork.Repository<EventGuest, int>();
var items = new List<EventProfileDto>();
foreach (var @event in events)
{
    var dto = mapper.Map<EventProfileDto>(@event);
    dto.TotalGuestCount = await guestRepo.CountWithSpecAsync(new EventGuestWithSpecs(@event.Id, ownerUserId, null, null));
    items.Add(dto);
}
```

Issues one extra `CountWithSpecAsync` round-trip per event in the page (up to 50, given `PaginationSpecification.MaxPageSize`) to populate `TotalGuestCount`. Contrast with `PersonService.GetAllAsync` and `EventGuestService.GetProgressAsync`, which both correctly fetch their aggregation data in one upfront query and reduce in C#.

Harmless at the personal scale this tool is built for (tens to a few hundred rows, per the plan's own reasoning elsewhere), but if this list endpoint ever sees more traffic or more events per user, it's worth collapsing to a single grouped-count query.

**Recommendation:** low priority — revisit only if `EventsController.GetAll` becomes a hot path.

---

## Not flagged (explicitly checked, no issue)

- DI lifetimes, using-directive order, naming conventions — all consistent with existing `AuthService`/`AuthController` precedent.
- No secrets added to `appsettings*.json`.
- No transactions needed anywhere in this feature (confirmed: every write path is a single `SaveChangesAsync`, including bulk guest-add via `AddRangeAsync`) — matches the plan's explicit reasoning.
- AutoMapper profiles and FluentValidation validators are picked up automatically by the existing assembly-scan registrations in `ServiceRegistration.AddApplicationServices()` — no registration changes were needed or missed.
- Migration (`20260726202448_AddPeopleGroupsEventsFeature`) is a clean, unedited EF Core scaffold in correct FK-safe table order.
