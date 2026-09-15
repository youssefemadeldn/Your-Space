# Session Handoff — 2026-09-15 (Row 10)

## What Was Done

Row 10 was queued by the prior handoff as "retire `DataRefreshBus`," on the assumption
(design doc §7, as originally written) that once People/Groups/Classification/Events all
moved to local-first `Stream` reads, every `DataScope` case would become dead and the whole
class could be deleted once only `DataScope.profile` remained.

A fresh audit of the actual code — not just the prior handoff's claimed live/dead sites —
found that assumption was wrong:

- `PersonDetailsCubit.getPersonById()` and `EventDetailsCubit.getEventById()` are still
  one-shot `Future` fetches, not drift `Stream`s. Their `DataRefreshBus` listeners are the
  only way these detail screens learn about an edit made on another screen.
- `EventsListCubit`'s list is stream-backed, but it still needs the bus to trigger a
  background pull for `Event.totalGuestCount` — a server-computed field a local drift
  upsert doesn't recompute.
- `PeopleListCubit.refreshGroups()` (the group-filter chip row) is still fetch-based and
  needs the `groups` scope.
- **`HomeStatsCubit`** — not mentioned anywhere in the prior handoff — subscribes to every
  `DataScope` unconditionally to refresh Home's counts/greeting. It has no stream of its
  own (does one-off count fetches across 3 repos), so it needs some "something changed"
  signal regardless of how many individual features migrate underneath it.

**Correction to the record:** the prior handoff (`010-...row9-shipped.md`) claimed
`PersonWizardCubit.notify(DataScope.groups)` / `.notify(DataScope.people)` were "dead
notifications" because Person/Groups are already local-first. This was wrong — it was
checked against only one downstream cubit each. `.people` feeds `PersonDetailsCubit`;
`.groups` feeds `PeopleListCubit.refreshGroups()`. Both are live. **Do not trust that
specific claim from the `010-...` handoff.**

The user was asked how to resolve this given Row 10's original goal wasn't achievable
without introducing regressions (stale detail screens, stale guest counts, stale Home
stats). Decision: **`DataRefreshBus` is reclassified as permanent cross-cutting
infrastructure**, not a migration shim scheduled for deletion. Row 10 scope shrank to: clean
up the one genuinely-dead spot found, and correct the design doc.

## Files Changed

| File | Change |
|---|---|
| `Your-Space-Mobile/lib/features/people/presentation/cubit/people_list_cubit/people_list_cubit.dart` | Removed the dead `case DataScope.people:` branch's stale no-op comment/isolated case, folding it into the existing no-op group alongside `events`/`eventGuests`/`profile`. Confirmed dead via: the cubit's own prior comment, `PeopleListCubit`'s primary read being `watchPersons()` (drift `Stream`), and the existing test `test/features/people/presentation/cubit/people_list_cubit_test.dart:274-296` which already asserts a `people` notification triggers nothing (unchanged, still passes). |
| `Your-Space-Mobile/doc/local-first-sync-design.md` | §7 rewritten from a retirement plan to a permanent-infrastructure rationale, documenting every live consumer per `DataScope` case and the rule that a case is only provably dead once *every* consumer (not just one cubit) is checked. §11 row 10 marked closed with the revised scope. |

## Files Audited (no changes needed)

| File | Checked For | Result |
|---|---|---|
| `injection_container.config.dart` (DI registration + 7 constructor-injection sites) | Whether any consumer of `DataRefreshBus` is itself dead | All 7 (`PersonDetailsCubit`, `EventDetailsCubit`, `PeopleListCubit`, `EventsListCubit`, `PersonWizardCubit`, `ProfileFormCubit`, `HomeStatsCubit`) are live. |
| `ProfileFormCubit` notify sites (3x, `profile`) | Dead/live | Live — sole path feeding `HomeStatsCubit`'s unconditional listener. |
| `PersonWizardCubit` notify sites (3x, `groups`/`people`) | Dead/live | Live (see correction above). |

## Pending Tasks

None outstanding for Row 10 — it is closed. `DataRefreshBus` is not scheduled for further
retirement work; see design doc §7 for what would have to change (reactive single-entity
detail streams for Person/Event, a locally-computed guest count, a reactive Home-stats
query) before deletion could even be considered again, and note that is a deliberate,
separate future effort, not something to attempt opportunistically.

## What's Next

No specific next row was queued as part of this session — the design doc's delivery table
(§11) has no further open rows beyond 10. Whoever picks up the next unit of work should
re-read `doc/local-first-sync-design.md` in full (not just §7/§11) to confirm there's
nothing else outstanding before choosing new scope.

## Key References

- `Your-Space-Mobile/doc/local-first-sync-design.md` — §7 (corrected) and §11 (row 10
  closed) are the authority for this row.
- `Your-Space-Mobile/doc/handoffs/005-local-first-sync/010-2026-09-15-row9-complete-events-relationships-images-shipped.md` —
  prior handoff; contains the incorrect "dead notification" claim corrected by this session.

## Clarifications & Decisions

| Question | Answer |
|---|---|
| Given the bus is still load-bearing in several spots the design doc didn't anticipate, how should Row 10 be scoped? | **Keep the bus permanently as an intentional aggregate-notification mechanism** — reclassify in the design doc rather than continue toward deletion; clean up only genuinely dead cases/calls now. |
| Branch mechanism for this (much smaller than originally queued) unit of work | **New branch** (`fix/row10-data-refresh-bus-reclassify`), one commit, one `--no-ff` merge to `production` — consistent with the Row 9 mechanism despite the smaller scope. |
| Pre-existing uncommitted handoff-doc changes (005→006 rename, 007-010 untracked) sitting in the working tree since before Row 9 | **Carry them into the new branch** — they ride along with this branch's commit rather than being committed separately or left alone. |
