# Local-First + Backend Sync — Design

> Authority for the **mechanism**. `CLAUDE.md` Architecture rule 7 is the authority for the
> **posture** (read path, write path, network-only exclusions, rollout order) — this document
> doesn't restate it, it implements it.

Status: **approved direction, not yet built**. Tier 1 ships first, on People, before anything
here is treated as final for other features.

---

## 1. Why, and why now

The app is 100% remote-only today — no local DB, `SharedPreferences`/`FlutterSecureStorage`
hold only tokens and flags. Every screen open is a network round-trip; every list is
server-paginated with up to 5 filter dimensions; every mutation blocks on connectivity.

This is personal contact/event data — hundreds of rows per user, not millions, entirely
single-owner (`OwnerUserId` on every row, no collaborative editing). That combination is what
makes local-first tractable: the **entire owned dataset can live on-device**, and the only
conflict vector is the same user on two devices, so last-write-wins is a legitimate policy,
not a compromise.

### Non-goals

- Multi-user collaboration / real-time presence — out of scope, the data model doesn't support it.
- Full offline creation of brand-new reference data hierarchies (Governorate → City →
  Neighborhood) — these are low-frequency, low-urgency writes; they go through the outbox
  like anything else but aren't a design pressure here.
- Conflict *merging* — last-write-wins only. A true 3-way merge isn't warranted for this data shape.

---

## 2. Three tiers, feature-by-feature

Each tier is independently shippable. Each feature migrates through all three tiers before
the next feature starts, so the pattern is proven once and then repeated — not built once
abstractly and rolled out cold everywhere.

```
Tier 1: Read cache          Tier 2: Write queue          Tier 3: Delta sync
cache-then-network    →     outbox + optimistic UI  →    watermark pull, no full refetch
(no backend change)         (no backend change)          (backend: expose updatedAt + /changes)
```

### Rollout order

| Order | Feature | Why here |
|---|---|---|
| 1 (pilot) | **People** | Most-used screen, has 5-dimension filtering (the hardest local-query case), `base_person_data_source` seam is the one CLAUDE.md already documents |
| 2 | **Groups** | Small, low cardinality, low risk — validates the pattern on a simple entity before Classification |
| 3 | **Classification** (Governorate/City/SubGroup/Neighborhood) | Reference data, mostly read, feeds People's filters — must be cached for People's filter chips to work fully offline |
| 4 | **Events + EventGuests** | Most complex: join to Person, server-computed progress/reciprocity stay network-only (§6) |
| Never migrated | Auth, Settings/UserSettings | Auth is inherently online-gated; settings are tiny, low-value to cache |

A feature not yet migrated keeps its plain remote-only data source and is unaffected —
CLAUDE.md rule 7 is explicit about this.

---

## 3. Tier 1 — Read cache (cache-then-network)

### Flow

```
Screen opens
    │
    ▼
Cubit subscribes to repository.watch<Entity>List(filters)   // Stream<List<Entity>>
    │
    ├─► drift emits whatever is cached NOW (possibly empty) — renders instantly
    │
    └─► repository kicks off a background remote fetch
             │
             ▼
        remote success → upsert rows into drift → drift Stream emits again → UI updates
        remote failure → swallowed at this layer; UI just keeps showing cached data
                          (a pull-to-refresh or explicit retry surfaces the failure instead)
```

No outbox yet — this tier is read-only caching. Mutations still go straight to the remote
data source and, on success, upsert the affected rows into drift directly (so the cache
doesn't go stale until the next scheduled sync). `DataRefreshBus` (`core/events/`) already
exists for this notification shape today — see §7 for how it's retired.

### Repository contract change

Today: `Future<Either<Failure, PaginatedResult<Person>>> getPersons(...)`
Tier 1: adds `Stream<List<Person>> watchPersons({filters})` alongside it — the existing
`Future`-returning method stays for one-shot calls (pull-to-refresh, `loadMore`) that don't
need a live subscription.

```dart
// domain/repositories/base_person_repository.dart
abstract class PersonRepository {
  Stream<List<Person>> watchPersons({
    int? groupId, int? subGroupId, int? governorateId, int? cityId, int? neighborhoodId,
    String? search,
  });
  Future<Either<Failure, Unit>> refreshPersons({/* same filters */});   // triggers a remote pull, result only signals success/failure of the fetch itself
  // getPersonById, createPerson, updatePerson, addOccasionHistory — unchanged shape, Tier 2 changes their body
}
```

`watchPersons` reads directly off drift with `AsNoTracking`-equivalent (drift `Stream` query,
naturally reactive). Filtering/pagination that today lives in the backend's `PersonsController`
query parameters is **reimplemented as a drift `where`/`limit` clause** — this is the one
piece of real client-side logic this tier introduces, and it's why drift (not Hive) is
mandatory: SQL `WHERE groupId = ? AND (subGroupId = ? OR ?) AND ...` is a direct port of the
backend's `PersonWithSpecs` predicate shape.

### Pagination becomes a local concern

Because the full owned dataset is cached, "page 2" is just `LIMIT 20 OFFSET 20` against the
local table — `loadMore()` no longer needs a network call once the initial sync has run. The
backend's paginated endpoint is still used for the *bulk sync fetch* (§5), not per-scroll.

---

## 4. Drift schema (Tier 1 baseline)

One `AppDatabase` (`lib/core/database/app_database.dart`), one table per synced entity, plus
two cross-cutting tables from day one (`outbox` unused until Tier 2, `sync_state` unused until
Tier 3 — created now so the schema doesn't need a breaking migration per tier).

```dart
// lib/core/database/tables/persons_table.dart
class PersonsTable extends Table {
  IntColumn get id => integer()();              // server id; negative = unsynced local temp id (Tier 2)
  TextColumn get name => text()();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get phoneNumber2 => text().nullable()();
  TextColumn get gender => text()();             // enum wire value, e.g. "Male"
  IntColumn get groupId => integer()();
  TextColumn get groupName => text()();
  IntColumn get subGroupId => integer().nullable()();
  TextColumn get subGroupName => text().nullable()();
  IntColumn get governorateId => integer()();
  TextColumn get governorateName => text()();
  IntColumn get cityId => integer().nullable()();
  TextColumn get cityName => text().nullable()();
  IntColumn get neighborhoodId => integer().nullable()();
  TextColumn get neighborhoodName => text().nullable()();
  TextColumn get primaryPhotoUrl => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get hasReciprocityHistory => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();  // Tier 3 watermark field — nullable until backend exposes it (§6)
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();  // tombstone flag, Tier 3
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();    // has a pending outbox row, Tier 2

  @override
  Set<Column> get primaryKey => {id};
}
```

Same shape for `GroupsTable`, `SubGroupsTable`, `GovernoratesTable`, `CitiesTable`,
`NeighborhoodsTable`, `EventsTable`, `EventGuestsTable` — one table per `core/entities/` or
feature `domain/entities/` class that gets a synced local source. Nested/child data that's
fetched per-parent today (`PersonOccasionHistory`, `PersonRelationship`, `PersonImage`) gets
its own table with a `personId` foreign column once that feature's Tier 1 lands — not part of
the People pilot's first cut, which covers the list + filter-critical fields only.

```dart
// lib/core/database/tables/outbox_table.dart — created now, populated starting Tier 2
class OutboxTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();          // 'person', 'group', 'eventGuest', ...
  IntColumn get entityId => integer()();          // local temp id or real server id
  TextColumn get operation => text()();           // 'create' | 'update' | 'delete'
  TextColumn get payloadJson => text()();          // the request body, already shaped like *_request.dart's toJson()
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}

// lib/core/database/tables/sync_state_table.dart — created now, populated starting Tier 3
class SyncStateTable extends Table {
  TextColumn get collection => text()();          // 'persons', 'groups', ...
  TextColumn get cursor => text().nullable()();    // opaque server watermark, null = never synced
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {collection};
}
```

`AppDatabase` is `@lazySingleton`, one instance for the app (per CLAUDE.md's DI table),
opened once in `injection_container` bootstrap before `runApp` — same tier as
`SharedPreferences`'s `@preResolve @singleton`.

---

## 5. Tier 2 — Write queue (outbox)

### Flow

```
User submits a mutation (create/update/delete)
    │
    ▼
Repository:
  1. Writes the change to drift immediately (optimistic) — UI updates via the Stream, instantly
  2. Appends one OutboxTable row in the SAME drift transaction as step 1
  3. Returns success to the cubit right away — no network wait
    │
    ▼
SyncService (background, connectivity-triggered):
  - Reads outbox rows oldest-first per entityType
  - POSTs/PUTs/DELETEs via the existing *_remote_data_source_impl (unchanged — Tier 2 doesn't
    touch ApiManager/AuthInterceptor/Failure mapping)
  - On success: deletes the outbox row; if it was a 'create', reconciles the local temp id →
    real server id (see below)
  - On failure: increments retryCount, stores lastError, retries with backoff; a
    non-retryable failure (validation, 409) surfaces to the UI via a "sync issue" badge —
    never silently dropped, never blocks other outbox rows
```

### Client temp-IDs

A record created offline has no server id yet. Local temp ids are negative integers
(`-DateTime.now().microsecondsSinceEpoch` truncated to fit `int`), chosen so they can never
collide with a real (positive) server id and need no separate "is this a temp id" column.

On successful create-sync, `SyncService`:
1. Receives the real server id in the response.
2. Runs one drift transaction: insert the row under the real id (copying the temp row's
   fields), delete the temp-id row, and **rewrite every foreign-key reference to the temp id**
   in dependent tables (e.g. an `EventGuestsTable.personId` created offline against a
   temp-id person) to the real id.
3. If any dependent row also has its own not-yet-synced outbox entry, that outbox row's
   `payloadJson` is patched to the real id before it's sent.

This reconciliation step is the single trickiest piece of Tier 2 — it's why creates that have
dependents (e.g. add-guest during person creation) need explicit test coverage before this
tier ships on a feature with such dependents (Events, not People).

### Conflict policy

Single-owner data (§1) → **last-write-wins by wall-clock `updatedAt`**, decided entirely
client-side for now (no server-side vector clock or ETag): if a Tier 3 pull returns a server
row whose `updatedAt` is newer than the local row's `updatedAt` *and* the local row has no
pending outbox entry, the server version wins outright. If the local row **does** have a
pending outbox entry, the local edit is presumed newer (it just happened) and is sent as-is;
the resulting server `updatedAt` becomes the new baseline on the next pull. No merge UI, no
"which version do you want" prompt — this is a deliberate simplicity trade-off enabled by
single-ownership, not an oversight.

### Retry/backoff

Exponential, capped: 5s → 15s → 60s → 5min → 15min, then hold until the next explicit trigger
(app foreground, connectivity regained, manual pull-to-refresh) or 6 retries, whichever
comes first. A row past its retry cap stays in the outbox (never silently dropped) and marks
the entity `isDirty` with a visible "couldn't sync" affordance — resolving it is a v2 UX
concern, not blocking for the first ship.

---

## 6. Tier 3 — Delta sync

### Backend changes required (none of this exists today)

| Change | Entities affected |
|---|---|
| Expose `updatedAt` (and `deletedAt` where the entity soft-deletes) on every response DTO that's cached client-side | Person, Event, Group, SubGroup, Governorate, City, Neighborhood, EventGuest |
| Add `GET /{collection}?since=<cursor>` returning **upserts** (rows changed after the cursor) **and tombstones** (ids removed since the cursor — soft-deleted or hard-deleted) | Same list |
| For hard-deletable join rows with no `DeletedAt` today (`EventGuest`, `PersonRelationship`, `PersonImage` — see backend `Person.cs`/`EventGuest.cs` comments) — either add a soft-delete column, or accept that Tier 3 for these three falls back to periodic full-refetch instead of delta (no tombstone stream possible without one) | EventGuest, PersonRelationship, PersonImage |
| A monotonic cursor, not wall-clock `updatedAt` alone — two rows updated in the same millisecond must not let one be silently skipped. Simplest option: reuse Postgres's own transaction ordering via a `bigserial` `SyncVersion` column per row (`ORDER BY SyncVersion`, cursor = last-seen `SyncVersion`), not a `DateTime` comparison | All synced entities |

Until these ship, Tier 3 for a feature runs in **"full refetch as delta" mode**: `since` is
ignored, the client always requests page 1..N of the full owned collection and diffs against
local drift by primary key (upsert what's returned, tombstone anything local that's absent
from the response — this only works correctly for **hard-deletes without a tombstone
problem**, i.e. it's an accurate stand-in for `EventGuest`/`PersonRelationship`/`PersonImage`
even before the backend work above lands, and a temporary stand-in for the soft-deletable
entities that becomes redundant once `since`/cursor exists).

### Client watermark

`SyncStateTable` (§4) holds one row per collection: `cursor` (opaque, whatever the backend's
`SyncVersion` scheme returns) and `lastSyncedAt` (for UI — "synced 2 minutes ago"). A pull:

```
1. Read stored cursor for the collection (null on first-ever sync)
2. GET /{collection}?since=<cursor>
3. Upsert every returned row into its drift table
4. Delete/tombstone-mark every id in the response's "removed" list
5. Store the response's new cursor
6. If a row upserted here has a pending outbox entry (edited offline since the last pull),
   apply the conflict policy from §5 rather than blindly overwriting
```

### When SyncService runs

- App foreground (cold start and resume from background)
- Connectivity regained (via the existing `ConnectivityHelper` stream)
- Manual pull-to-refresh on a screen (foreground-triggers a pull for that screen's
  collection specifically, not a full sync)
- A periodic timer while foregrounded (15 min) as a floor, so a long foreground session
  doesn't go stale

Never on a fixed background-fetch schedule while backgrounded — this app doesn't need
push-driven background sync, and adding `WorkManager`/`BackgroundFetch` plumbing for it isn't
justified by the data's update frequency (personal contacts change rarely). Revisit only if a
real usage pattern demands it.

---

## 7. Retiring `DataRefreshBus`

`core/events/data_refresh_bus.dart` exists today because `StatefulShellRoute.indexedStack`
keeps branch cubits alive forever and nothing else tells a live cubit that data changed
elsewhere (see its own doc comment). Once a feature is on a drift `Stream`, this problem
disappears structurally — every cubit watching the same table sees the same write the instant
it lands, with no explicit notification needed.

**Migration is per-feature, not a flag day:** as each feature moves to Tier 1, its
`DataScope` case (`people`, `groups`, `events`, `eventGuests`, `classification`) is deleted
from every listener, and its `_dataRefreshBus.notify(...)` call sites in action cubits are
deleted too. `DataScope.profile` (Settings, never migrated per §2) is the only case expected
to survive long-term. Once every other case is gone, delete `DataRefreshBus` itself rather
than leaving a one-case bus alive.

---

## 8. What stays network-only

Per CLAUDE.md rule 7 — these are **server-computed**, not stored facts, so caching them is
either wrong (goes stale instantly) or meaningless (recomputing locally would just
reimplement the backend's business logic):

| Value | Source |
|---|---|
| `EventGuestProgressSummary` (`GetProgressAsync`) | live aggregate over current guest rows |
| Reciprocity suggestions (`GetReciprocitySuggestionsAsync`) | live cross-reference over occasion history |
| `Person.hasReciprocityHistory` | flag computed server-side from occasion history at read time |
| `GroupGuestProgress` per-group counts | same aggregate family as progress summary |

These repository methods keep their current `Future<Either<Failure, T>>` shape unchanged —
no `watch*` variant, no drift table, called straight through to the remote source exactly as
today. A cubit that needs one of these alongside cached list data (e.g. the guest screen
showing both the cached guest list and the live progress bar) combines a `watch` stream with
a one-shot `Future` call — two separate data flows in the same screen, not a stretch of
either pattern to cover both.

---

## 9. Image uploads

`PersonImageService`/`PersonImagesController` (multipart upload) is a write like any other,
so it goes through the outbox, with one difference: the payload is a **local file reference**
(a path under the app's document directory that the picked/captured image was copied to at
selection time — never the transient `image_picker` cache path, which the OS can reclaim),
not JSON.

```dart
// OutboxTable row for an image upload
entityType: 'personImage'
operation: 'create'
payloadJson: '{"personId": 42, "localFilePath": "/.../app_docs/staged_images/<uuid>.jpg", "isPrimary": true}'
```

`SyncService` reads the file off disk at replay time and performs the existing multipart
`UploadAsync` call unchanged. If the file is missing at replay time (user cleared app storage
between staging and sync — an edge case, not the common path), the outbox row is dropped with
a logged warning rather than retried forever. The staged file is deleted only after a
confirmed-successful upload, never optimistically.

---

## 10. Auth interaction

Per CLAUDE.md Architecture rule 1 (amended): a failed token refresh clears tokens and routes
to login, but the drift database is untouched. Concretely:

- `SyncService` checks auth state before each pull/replay cycle; if no valid token is present,
  it skips the cycle silently rather than erroring (mirrors `AuthInterceptor`'s "skip
  silently" behavior for a null token on a request).
- On logout (explicit, or forced by a failed refresh), the local cache is **not** cleared —
  a returning user (re-login on the same device) sees their cached data instantly instead of
  a cold empty state, and Tier 3 reconciles it on the next successful pull.
- The one exception: **account deletion** (`DeleteAccountAsync`) clears the entire local
  database in the same flow that clears secure storage — the data is gone server-side, so
  keeping a stale local copy around is actively wrong, not a convenience.
- If a different user logs in on the same device (device-sharing scenario, not the common
  case but must not corrupt data): every synced table is keyed by server-assigned ids that
  are only meaningful per-owner, so a full local wipe + fresh Tier-1 seed is triggered on
  **login success when the returned user id differs from the last-logged-in user id** stored
  alongside the token. This check is cheap and prevents a real data-leak class of bug.

---

## 11. Delivery plan

Each row is a shippable PR-sized unit; a feature doesn't move to its next row until the
previous one is verified.

| # | Scope | Feature | Backend change |
|---|---|---|---|
| 1 | `AppDatabase` scaffold: `PersonsTable`, `OutboxTable` (unused), `SyncStateTable` (unused), DI wiring | — (infra) | none |
| 2 | Tier 1 read cache: `watchPersons`, local data source, cache-then-network in `PeopleListCubit` | People | none |
| 3 | Tier 2 outbox: create/update person, temp-id reconciliation, `SyncService` replay loop | People | none |
| 4 | Tier 3 full-refetch-as-delta pull for Person (interim, no `since`) | People | none |
| 5 | Backend: `UpdatedAt`/`SyncVersion` on `PersonProfileDto`/`PersonDetailsDto`, `GET /persons/changes?since=` | People | **yes** |
| 6 | Switch Person's Tier 3 pull from full-refetch to real delta | People | (consumes #5) |
| 7 | Repeat rows 1–6 for Groups | Groups | as needed |
| 8 | Repeat for Classification (Governorate/City/SubGroup/Neighborhood) | Classification | as needed |
| 9 | Repeat for Events + EventGuests, including the soft-delete-column decision for `EventGuest`/`PersonRelationship`/`PersonImage` (§6) | Events | **yes** |
| 10 | Retire `DataRefreshBus` once its last `DataScope` case (other than `profile`) is gone | — (cleanup) | none |

People's rows 1–6 are the reference implementation every later feature copies — get code
review depth there, move faster on the repeats.

---

## 12. Open questions (track, don't block on)

- **Retry-cap UX** — what a user sees for a permanently-stuck outbox row (§5) is a v2 design,
  not specified here; ship with a minimal "couldn't sync" indicator for v1.
- **`SyncVersion` column migration cost** — adding it to 7+ backend tables is a real (if
  mechanical) migration; sequence it as its own PR per entity in row 5/9 above, not a
  big-bang schema change.
- **Storage growth** — no expiry/eviction planned for synced tables (unlike the
  per-entity-cache eviction concern in `flutter_feature_prompt.md`'s storage-backend section)
  because the dataset is the user's *entire* owned collection by design, not a growing
  view-history cache. Revisit only if real device-storage complaints surface.
