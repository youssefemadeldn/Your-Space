# Session Handoff — 2026-09-11

> **OUT OF PREVIOUS SESSION — NEW SESSION START**
>
> Read this file first. It contains everything from the prior session.
> Then read `doc/local-first-sync-design.md` in full before writing any code —
> that document, not this handoff, is the authority for the sync mechanism.

## What Was Done

**1. UX audit (discussion only, no code changed)**
Explored the mobile app's UX primitives and found: zero `HapticFeedback` usage, zero `Hero`
transitions, only 2 `AnimatedContainer`s app-wide, no custom route transitions, the `shimmer`
package installed but never used (loading = bare `CircularProgressIndicator` via
`AppLoadingIndicator`), no dark theme. Gave a tiered set of recommendations (skeleton loaders,
haptics, `AnimatedSwitcher` state transitions, `Hero` on avatars, animated stat counters,
staggered list entrances, dark mode, reciprocity-suggestions card-stack UI). **Nothing from
this list has been implemented yet** — it's a backlog, not committed work.

**2. Local-first + backend-sync architecture proposal**
Explored the current data layer (100% remote, no local DB — only `SharedPreferences` +
`FlutterSecureStorage`) and the backend (`Your-Space-Backend`): confirmed every synced entity
already has `CreatedAt`/`UpdatedAt`/`DeletedAt` server-side, but **`UpdatedAt` is never
exposed in any DTO** and **no delta/`changes` endpoint exists**. Confirmed data is strictly
single-owner (`OwnerUserId` on every row) — no collaborative-editing conflict vector.
Proposed 3 tiers: read cache → write outbox → delta sync. **User accepted all 3 tiers,
rolled out feature-by-feature.**

**3. Ran `/flutter-update-rules-files-sync`**
Updated the Flutter rule files to state the *posture* (not the mechanism — that's the design
doc's job) before the design doc was written, per the user's explicit request and the user's
answer to a scoping question ("posture + invariants only" vs "full detail now" vs "just fix
contradictions" — user picked **posture + invariants only**).

**4. Wrote `doc/local-first-sync-design.md`**
Full mechanism design: drift schema (`PersonsTable`, `OutboxTable`, `SyncStateTable`), Tier 1
cache-then-network flow, Tier 2 outbox + temp-ID reconciliation + last-write-wins conflict
policy, Tier 3 delta sync incl. a "full-refetch-as-delta" interim mode that ships **before**
any backend change, `DataRefreshBus` retirement plan, the network-only boundary
(reciprocity suggestions / guest progress / `hasReciprocityHistory`), image-upload queueing,
auth interaction (logout keeps cache, account deletion wipes it, **cross-user device switch
triggers a full wipe+reseed** — a real data-leak class caught while writing this section), and
a 10-row PR-sized delivery plan.

## Files Changed

| File | Change | Why |
|---|---|---|
| `CLAUDE.md` | `lib/core/` table: +`database/`, +`sync/` rows. "Local data source" paragraph reframed (drift mandatory for synced features). Architecture rule 1 (auth): failed refresh gates writes but never wipes local DB. **New Architecture rule 7 "Local-first for synced features"** (the canonical posture statement). DI table: +`AppDatabase`/DAOs, +`SyncService`. Completion checklist: +1 item. | Make the rule set state the accepted direction before the design doc existed |
| `.claude/rules/flutter_feature_prompt.md` | "Choosing a storage backend" table: last row now points to local-first sync instead of "out of scope". New "Synced (local-first) features" subsection under the data-source contract section. §12 checklist: new "Sync" group (5 items). §13 anti-patterns: +4 rows (remote call on read path, direct remote write, wiping DB on failed refresh, awaiting `SyncService` before render). | Practical "how" mirroring CLAUDE.md's rule 7 |
| `.claude/templates/layers/T1-cubit.md` | Pointer-note: synced-feature cubits watch a `Stream`; full template rewrite pending design-doc approval | Template sync per skill Phase 5, deferred per chosen scope |
| `.claude/templates/layers/T2-data-source.md` | Pointer-note: synced features need `base_*` + drift-backed local impl | Same |
| `.claude/templates/layers/T3-repository.md` | Pointer-note: synced-feature repos read local + route writes through outbox | Same |
| `doc/local-first-sync-design.md` | **New file** — full mechanism design, see below | The design doc requested this session |

None of these touched `lib/` — **zero application code has been written yet.** Everything so
far is rules + design documentation.

## Pending Tasks

- [ ] **Row 1 of the delivery plan** (`doc/local-first-sync-design.md` §11): scaffold
      `AppDatabase` (drift) at `lib/core/database/app_database.dart` with `PersonsTable`,
      `OutboxTable` (unused until Tier 2), `SyncStateTable` (unused until Tier 3). Register as
      `@lazySingleton`, opened before `runApp` (same tier as `SharedPreferences`'s
      `@preResolve @singleton` in `register_module.dart`). Add the `drift` package (+
      `drift_dev`/`build_runner` codegen step) to `pubspec.yaml` — this is a new dependency and
      must clear the "necessary and justified" bar per CLAUDE.md's Dependencies rule (it does —
      see design doc §4 for why drift specifically, not Hive).
- [ ] Row 2: Tier 1 read cache for People — `watchPersons()` `Stream` method on
      `PersonRepository`, drift-backed `person_local_data_source_impl.dart`, wire
      `PeopleListCubit` to cache-then-network (design doc §3).
- [ ] Row 3: Tier 2 outbox for People — create/update person through the outbox, temp-ID
      reconciliation (design doc §5 — flagged as the trickiest part of the whole plan).
- [ ] Row 4: Tier 3 full-refetch-as-delta pull for Person (no backend change needed yet).
- [ ] Row 5 (**backend work, `Your-Space-Backend` repo**): expose `UpdatedAt`/`SyncVersion` on
      `PersonProfileDto`/`PersonDetailsDto`, add `GET /persons/changes?since=`. This is the
      first point where the .NET backend needs to change — everything before it is mobile-only.
- [ ] Row 6: switch Person's Tier 3 pull from full-refetch to real delta.
- [ ] Rows 7–9: repeat rows 1–6 for Groups, then Classification, then Events+EventGuests
      (Events needs the `EventGuest`/`PersonRelationship`/`PersonImage` soft-delete-column
      decision from design doc §6 before its Tier 3).
- [ ] Row 10 (cleanup): retire `DataRefreshBus` once its last non-`profile` `DataScope` case
      is gone.
- [ ] (Backlog, not scheduled) UX polish items from the first half of this session — skeleton
      loaders, haptics, route/state transitions, `Hero` avatars, dark mode. Not blocking the
      sync work; pick up whenever, in any order.

## What's Next (ordered)

1. Read `doc/local-first-sync-design.md` in full (it's the mechanism authority — this handoff
   only summarizes it).
2. Start delivery-plan row 1: add `drift`/`drift_dev` to `pubspec.yaml`, scaffold
   `AppDatabase` + the three tables per design doc §4, wire DI.
3. Row 2 follows immediately after — Tier 1 is meant to be verified end-to-end on People
   before row 3 (outbox) starts, per the design doc's "don't move to the next row until the
   previous is verified" rule (design doc §11 intro).

## Key References

- `doc/local-first-sync-design.md` — the mechanism design (schema, flows, delivery plan).
  **Read this before writing any sync code.**
- `CLAUDE.md` Architecture rule 7 — the posture/invariants (read path, write path,
  network-only exclusions, rollout order). Rules and design doc must never be edited to
  contradict each other — if a future decision changes one, check the other.
- `.claude/rules/flutter_feature_prompt.md` — "Choosing a storage backend" section and the
  new "Synced (local-first) features" subsection.
- `lib/features/people/presentation/cubit/people_list_cubit/` — the cubit Tier 1 row 2 will
  modify; already has 5-dimension filtering (group/subGroup/governorate/city/neighborhood)
  that the local drift query needs to reproduce.
- `lib/core/events/data_refresh_bus.dart` — the mechanism Tier 1 gradually replaces (design
  doc §7); do not delete until every non-`profile` `DataScope` case is migrated.
- Backend repo: `Your-Space-Backend/YourSpace.Data/Entities/Person.cs` (and sibling entities)
  — already has `CreatedAt`/`UpdatedAt`/`DeletedAt`; row 5's backend work exposes these, it
  doesn't add them.

## Clarifications & Decisions

| Question | Answer |
|---|---|
| Which tier(s) of the local-first proposal to build? | All 3 tiers (read cache, write outbox, delta sync) |
| Rollout strategy? | Feature-by-feature, not all-at-once. Order: People (pilot) → Groups → Classification → Events |
| How much of the new architecture should the rule files bake in now, given the design doc comes right after? | **"Posture + invariants only"** — rules state direction/non-negotiables and point to the design doc for mechanism; NOT "full detail now" (rewrite templates immediately) or "just fix contradictions" (defer everything new to the doc alone) |

## Notes

- The backend context that got auto-injected mid-session (the `.NET` `CLAUDE.md`/rule files)
  is **not applicable to the mobile project** — per the repo-root `CLAUDE.md`'s cross-project
  rule, each project's rules stay strictly inside its own folder. It was correctly ignored
  when running `/flutter-update-rules-files-sync`; a new session should do the same if it
  recurs.
- Local-first work is entirely additive to the mobile repo until delivery-plan row 5 — rows
  1–4 need zero backend changes and can proceed independently of `Your-Space-Backend` work.
- The device-user-switch wipe+reseed rule (design doc §10) was not something the user asked
  for explicitly — it surfaced while reasoning through the auth-interaction section and closes
  a real cross-user data-leak class on shared devices. Treat it as a requirement, not an
  optional nicety, when row 2+ touches login/logout flows.
