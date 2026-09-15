# Session Handoff — 2026-09-15

> **OUT OF PREVIOUS SESSION — NEW SESSION START**
>
> Read this file first. It contains everything from the prior session.

## What Was Done

Row 9 of the local-first sync rollout (`doc/local-first-sync-design.md`) was planned and
implemented **in full, in one continuous sprint, on one branch, with exactly one merge** —
per the user's explicit directive: *"not event drift scaffold, one plan one sprint one
branch one merge, understanded?"*. This is a deliberate change from the Row 1–8 cadence
(one branch/commit/merge/push per sub-step) and **the mechanism the user wants repeated
for Row 10**.

- Branch `feature/row9-events-eventguests-relationships-images`, 14 commits, merged into
  `production` with `--no-ff` as commit `df81d06`, then pushed to `origin/production`.
- Scope grew beyond the design doc's row 9 (`Events + EventGuests` only) — the user
  explicitly added `PersonRelationship` and `PersonImage` into Row 9 during planning, even
  though the design doc's own rollout table (§2) never lists them and §4 explicitly defers
  them out of the People pilot's first cut. **Row 10 should not assume any remaining
  entity is still unmigrated without checking current code** — this session found the
  rollout list can be extended mid-flight by explicit user decision.
- Four entities shipped: **Event** (full 6-step arc, real cursor-based delta sync, mirrors
  Person/Group/Classification's shape), **EventGuest**, **PersonRelationship**,
  **PersonImage** (each a 4-step arc: scaffold → Tier 1 read cache → Tier 2 outbox → Tier 3
  **permanent** full-refetch-as-delta — no `SyncVersion` column, no real delta, ever, by
  deliberate decision, since these three are hard-delete-only entities).
- Two new reconciliation shapes not seen in Rows 1–8:
  - **Dual-parent reconciliation** (EventGuest has both `eventId` and `personId` FKs) —
    `EventLocalDataSourceImpl.reconcileCreatedEvent` (new) and
    `PersonLocalDataSourceImpl.reconcileCreatedPerson` (extended) both rewrite
    `EventGuestsTable` for a resolved temp id.
  - **Symmetric-pair reconciliation** (PersonRelationship's backend auto-creates a linked
    inverse row) — the client now optimistically inserts both forward+inverse rows under
    paired temp ids, one outbox row, `confirmSyncedPersonRelationshipPair` resolves both
    atomically. Backend's `PersonRelationshipDetailsDto`/create response was extended with
    `InverseId`/`InverseRelationType` to support this.
- `PersonLocalDataSourceImpl.reconcileCreatedPerson` is now the widest reconciliation
  method in the codebase — it rewrites four dependent shapes for one resolved Person temp
  id: `EventGuestsTable.personId`, `PersonRelationshipsTable.personId` **and**
  `.relatedPersonId` (dual-column), and `PersonImagesTable`-adjacent payload rewrites (no
  table row pre-upload). See `Your-Space-Mobile/lib/features/people/data/datasources/person_local_data_source_impl.dart`.
- Fixed a real Postgres bug found while running `dotnet ef database update` against a real
  local instance for the first time this rollout: `setval(seq, 0)` throws on an empty
  table (sequence `MINVALUE` defaults to 1). Patched with `GREATEST(...,1)` + conditional
  `is_called` across **all 7** `AddXSyncVersion` migrations (Person, Group, Governorate,
  City, SubGroup, Neighborhood, and the new Event one) — not just the new one.
- Verification at each entity's final step: `fvm flutter analyze` clean throughout,
  `fvm flutter test` grew 572→696 (0 failures), backend `dotnet build` clean,
  `dotnet test` grew 358→379 (0 failures), `dotnet ef database update` run successfully
  end-to-end against real Postgres.

## Files Changed

133 files changed (12,204 insertions, 1,910 deletions) across the merge commit. Full list
is in `git show --stat df81d06` — not reproduced here. Highest-signal new files for Row 10
context:

| File | Why it matters for Row 10 |
|---|---|
| `Your-Space-Mobile/lib/core/events/data_refresh_bus.dart` | The thing Row 10 deletes. Enum: `DataScope { people, groups, events, eventGuests, profile }`. |
| `Your-Space-Mobile/lib/features/events/presentation/cubit/event_details_cubit/event_details_cubit.dart:23` | Still listens for `DataScope.events`/`DataScope.eventGuests` — retire in Row 10. |
| `Your-Space-Mobile/lib/features/events/presentation/cubit/events_list_cubit/events_list_cubit.dart:39` | Same — still listens for `DataScope.events`/`DataScope.eventGuests`. |
| `Your-Space-Mobile/lib/features/people/presentation/cubit/people_list_cubit/people_list_cubit.dart:62-73` | Switches on **all five** `DataScope` cases including `people`/`groups`/`events`/`eventGuests`/`profile` — needs per-case audit, see below. |
| `Your-Space-Mobile/lib/features/people/presentation/cubit/person_details_cubit/person_details_cubit.dart:20` | Still listens for `DataScope.people`. |
| `Your-Space-Mobile/lib/features/people/presentation/cubit/person_wizard_cubit/person_wizard_cubit.dart:245,541,556` | Still **calls** `_dataRefreshBus.notify(DataScope.groups)` / `.notify(DataScope.people)` — these are dead notifications now that Person (Rows 1–6) and Groups (Row 7) are both already local-first; a `Stream`-watching cubit doesn't need a bus poke. |
| `Your-Space-Mobile/lib/features/settings/presentation/cubit/profile_form_cubit/profile_form_cubit.dart:48,74,89` | Still calls `notify(DataScope.profile)` — `profile`/Settings was **never** migrated to local-first per design doc §2, so this is the one case expected to survive Row 10 (see design doc §7: "`DataScope.profile` ... is the only case expected to survive long-term"). |

## Files Audited (no changes)

| File | Checked For | Result |
|---|---|---|
| `Your-Space-Backend/YourSpace.Services/Services/PersonRelationshipService/PersonRelationshipService.cs:58-79` (`CreateAsync`) | Whether `person-relationships`'s new flat "all mine" endpoint needs an `OR`-both-sides ownership join (an open question carried from Row 9's plan) | **Resolved, no code change needed**: `relatedPerson` is looked up via `PersonWithSpecs(dto.RelatedPersonId, ownerUserId)` — the **same** `ownerUserId` as the primary person. The domain already guarantees both sides of a relationship share one owner (you can only link to your own People). A single join on `PersonId`'s owner is correct; no `OR` was added and none is needed. |

## Pending Tasks

- [ ] **Row 10: retire `DataRefreshBus`** — per design doc §7 and §11 (delivery table row 10:
      "Retire `DataRefreshBus` once its last `DataScope` case (other than `profile`) is
      gone — (cleanup), depends on: none"). This is confirmed as the next row in sequence.
- [ ] Audit — do NOT assume, grep and confirm live — which `DataScope` cases have zero
      remaining listeners/notifiers as of the start of the new session (code may have
      shifted since this handoff was written): known live listener sites as of now are
      `event_details_cubit.dart:23`, `events_list_cubit.dart:39`, `people_list_cubit.dart:62-73`,
      `person_details_cubit.dart:20`; known live notify-call sites are
      `person_wizard_cubit.dart:245,541,556` and `profile_form_cubit.dart:48,74,89`.
- [ ] Delete each dead `DataScope` case from the enum and every switch/listener/notify
      call site that references it, one case at a time, verifying `fvm flutter analyze`
      stays clean after each deletion (a case still referenced somewhere will fail to
      compile once removed from the enum, which is a useful correctness check as you go).
- [ ] Once only `DataScope.profile` remains as a live case, decide (per design doc §7)
      whether to delete `DataRefreshBus` itself, or keep the class with a single-case enum
      if Settings truly never migrates — design doc's stated intent is to delete it once
      the last non-profile case is gone, but confirm this is still desired since deleting
      a whole pub/sub class for one remaining case is a bigger structural change than the
      earlier per-entity Row 9 deletions.

## What's Next (ordered)

1. Start the new session by reading this file, then re-verify the "Files Changed" /
   "Pending Tasks" grep results above are still accurate (the codebase may have moved).
2. Enter plan mode and produce **one comprehensive Row 10 plan** covering: the full
   `DataScope` audit, every listener/notify site to delete, the `DataRefreshBus` disposition
   decision, and the associated test-file updates (every cubit test file that currently
   constructs a `DataRefreshBus` and asserts on bus notifications for a case being deleted
   needs its test updated/removed, not just the production code).
3. Get the plan approved via `ExitPlanMode`.
4. Implement the **entire** approved plan in one continuous sprint, on **one** feature
   branch (suggested name: `feature/row10-retire-data-refresh-bus`), with **exactly one**
   final `--no-ff` merge into `production` and one push — mirroring Row 9's execution
   mechanism exactly, not the earlier per-substep cadence. Confirm this mechanism with the
   user again before starting, since it was a one-off directive for Row 9 and hasn't been
   standing instruction before now — but the user has now asked for it explicitly for
   Row 10 too.
5. Verify: `fvm flutter analyze` clean, `fvm flutter test` green (expect the count to move
   from 696 as bus-related tests are deleted/updated — a drop in test count here is
   expected and fine, unlike every prior row where the count only grew), and a final
   manual check that Settings/profile-flow notifications still work if `DataRefreshBus`
   survives for that one case.

## Key References

- `Your-Space-Mobile/doc/local-first-sync-design.md` — §7 ("Retiring `DataRefreshBus`") and
  §11 (delivery table, row 10) are the authority for this row's scope.
- `Your-Space-Mobile/doc/handoffs/005-local-first-sync/009-2026-09-15-row8-complete-classification-shipped.md` —
  prior handoff, referenced by Row 9's plan for known mocktail/test gotchas that likely
  still apply.
- `/Users/youssefemadeldin.ai/.claude/plans/i-need-you-plan-fluttering-island.md` — the
  full approved Row 9 plan (kept for reference on the "one plan, one sprint" plan-writing
  style/depth the user approved, to replicate for Row 10's plan).

## Clarifications & Decisions

| Question | Answer |
|---|---|
| Should EventGuest/PersonRelationship/PersonImage get a soft-delete `DeletedAt` column and real cursor-based delta, or stay permanently hard-delete with full-refetch-as-delta? | **Keep hard-delete, use full-refetch-as-delta permanently** (Recommended option chosen). |
| Should PersonRelationship and PersonImage be included in Row 9's scope, even though the design doc doesn't list them in the rollout order and explicitly defers them out of the People pilot's first cut? | **Migrate them too, as part of Row 9** (user overrode the "Recommended: leave out of scope" option). |
| Execution mechanism for implementing the approved Row 9 plan | **"not event drift scaffold, one plan one sprint one branch one merge, understanded?"** — full plan implemented in one sprint, one branch, one final merge. This is the mechanism the user now wants repeated for Row 10 (per this session's request). |
| How to proceed once Row 9 was fully implemented on the feature branch | **"Merge to production and push now"** (Recommended option chosen) — executed as `git checkout production && git pull && git merge --no-ff feature/row9-... && git push origin production`. |

## Notes

- The working tree has had pre-existing, unrelated uncommitted handoff-doc changes
  present since before Row 9's session started (a rename of an older handoff file plus a
  few untracked new handoff files in this same `005-local-first-sync/` folder). These were
  deliberately left untouched/unstaged through all of Row 9's commits — verify at the start
  of the Row 10 session whether they're still sitting there uncommitted and, if so, ask the
  user whether to commit or discard them before starting new work, rather than silently
  carrying them forward again.
- `PersonLocalDataSourceImpl.reconcileCreatedPerson` is now doing meaningfully more than
  any other reconciliation method in the codebase (4 dependent shapes, one with 2 FK
  columns). If Row 10 or later work touches this method again, read it in full first —
  it's a good candidate for a future readability pass (splitting into named private
  helpers per dependent-table block), but that's optional cleanup, not required for Row 10.
- The empty-table `setval` fix this session applied is now baked into all 7 existing
  `AddXSyncVersion` migrations. Any *future* row that adds an 8th such migration (there
  are none left after Event, per the migrated-entity list) doesn't need this fix repeated —
  documented here only so a future session doesn't waste time rediscovering why the fix
  pattern already exists in git history.
