import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/governorate.dart';

/// Drift-backed local store for Governorates — the Tier 1 read path
/// (CLAUDE.md Architecture rule 7), mirrors `GroupLocalDataSourceImpl`. Does
/// not implement `BaseGovernorateDataSource`: it's typed concretely in
/// `GovernorateRepositoryImpl` so its `save*` write methods (no remote
/// equivalent) are reachable.
@Named('local')
@lazySingleton
class GovernorateLocalDataSourceImpl {
  final AppDatabase _db;

  GovernorateLocalDataSourceImpl(this._db);

  /// Reactive read path. `limit` grows as `loadMore()` is called on the
  /// caller side; this always queries from row 0 (no offset) rather than
  /// tracking a separate page window.
  Stream<List<Governorate>> watchGovernorates({String? search, required int limit}) {
    final query = _db.select(_db.governoratesTable)
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.name)])
      ..limit(limit);
    if (search != null && search.isNotEmpty) {
      final pattern = '%$search%';
      query.where((t) => t.name.like(pattern) | t.nameAr.like(pattern));
    }
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  /// One-shot exact count for the same filter set — backs `hasNextPage`
  /// without a `length == limit` heuristic.
  Future<int> countGovernorates({String? search}) {
    final countExp = _db.governoratesTable.id.count();
    final query = _db.selectOnly(_db.governoratesTable)..addColumns([countExp]);
    query.where(_db.governoratesTable.isDeleted.equals(false));
    if (search != null && search.isNotEmpty) {
      final pattern = '%$search%';
      query.where(
        _db.governoratesTable.name.like(pattern) | _db.governoratesTable.nameAr.like(pattern),
      );
    }
    return query.map((row) => row.read(countExp) ?? 0).getSingle();
  }

  /// Tier 1 upsert, no tombstoning — kept as a documented primitive for a
  /// future caller that wants a plain bulk replace. `refreshGovernorates()`
  /// (Tier 3) uses `applyGovernorateChanges` (row 8.6) instead.
  Future<void> saveGovernorates(List<Governorate> governorates) => _db.batch(
        (batch) => batch.insertAllOnConflictUpdate(
          _db.governoratesTable,
          governorates.map(_toCompanion).toList(),
        ),
      );

  /// No remote equivalent — single-row upsert after a successful
  /// create mutation. This was the transitional Tier 1 write path used by
  /// `GovernorateRepositoryImpl.createGovernorate` before row 8.3 moved it to
  /// the outbox (mirrors `GroupLocalDataSourceImpl.saveGroup`) — kept as a
  /// documented primitive, same reasoning as Group's own `saveGroup`.
  Future<void> saveGovernorate(Governorate governorate) =>
      _db.into(_db.governoratesTable).insertOnConflictUpdate(_toCompanion(governorate));

  /// Tier 2 optimistic write (design doc §5): writes [governorate] into
  /// GovernoratesTable (marked dirty) and appends one OutboxTable row, in the
  /// same drift transaction. Returns the new outbox row's id so the
  /// repository's `createGovernorateAndSync` can ask `SyncService` to replay
  /// this specific row immediately. Governorate has no update/delete on
  /// mobile, so [operation] is always `'create'` — the parameter is kept for
  /// shape-parity with `GroupLocalDataSourceImpl.queueGroupMutation`.
  Future<int> queueGovernorateMutation({
    required Governorate governorate,
    required String operation, // 'create' — Governorate has no update/delete
    required String payloadJson,
  }) =>
      _db.transaction(() async {
        await _db.into(_db.governoratesTable).insertOnConflictUpdate(
              _toCompanion(governorate, isDirty: true),
            );
        return _db.into(_db.outboxTable).insert(
              OutboxTableCompanion.insert(
                entityType: 'governorate',
                entityId: governorate.id,
                operation: operation,
                payloadJson: payloadJson,
              ),
            );
      });

  /// Kept as a documented, currently-unreachable primitive — mirrors
  /// `GroupLocalDataSourceImpl.confirmSyncedGroup`. Governorate has no
  /// update path on mobile, so nothing ever calls this today; it exists so a
  /// future update feature has the same confirm-after-sync shape every other
  /// entity uses, rather than needing to invent one from scratch.
  Future<void> confirmSyncedGovernorate(Governorate governorate, {required int replayedOutboxRowId}) =>
      _db.transaction(() async {
        await _db.into(_db.governoratesTable).insertOnConflictUpdate(_toCompanion(governorate));
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();
      });

  /// Tier 2 temp-id reconciliation (design doc §5) after a queued 'create'
  /// syncs. One transaction:
  ///  1. insert the confirmed server row under [realGovernorate].id
  ///  2. delete the temp-id row
  ///  3. delete the just-replayed outbox row
  ///  4. rewrite any dependent `CitiesTable` row (and any still-queued
  ///     `entityType='city'` outbox payload) that references [tempId] — see
  ///     row 8.9, City's own Tier 2 step, which is what actually adds this
  ///     4th step; nothing depends on Governorate's temp id yet at row 8.3.
  Future<void> reconcileCreatedGovernorate({
    required int tempId,
    required Governorate realGovernorate,
    required int replayedOutboxRowId,
  }) =>
      _db.transaction(() async {
        await _db.into(_db.governoratesTable).insertOnConflictUpdate(_toCompanion(realGovernorate));
        await (_db.delete(_db.governoratesTable)..where((t) => t.id.equals(tempId))).go();
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();
      });

  /// Tier 3 "full refetch as delta" (design doc §6): [serverGovernorates] is
  /// the complete, just-fetched owned+global collection. Diffs it against
  /// local drift by id in one transaction:
  ///  - a row with `isDirty == true` is left untouched — it has a pending
  ///    outbox entry, so the local edit is presumed newer
  ///  - every other server row is upserted (clean: not dirty, not deleted)
  ///  - every local row with id > 0, isDirty == false, whose id is absent
  ///    from [serverGovernorates] is soft-tombstoned (`isDeleted = true`) — a
  ///    temp (negative) id is never a tombstone candidate; it was never on
  ///    the server to begin with
  ///
  /// No longer used by `GovernorateRepositoryImpl.refreshGovernorates()`
  /// since row 8.6 switched Governorate to real deltas
  /// ([applyGovernorateChanges]) — kept as a documented full-snapshot
  /// primitive, mirrors `GroupLocalDataSourceImpl.applyGroupsSnapshot`'s own
  /// post-7.6 state.
  Future<void> applyGovernoratesSnapshot(List<Governorate> serverGovernorates) => _db.transaction(() async {
        final dirtyIds =
            (await (_db.select(_db.governoratesTable)..where((t) => t.isDirty.equals(true))).get())
                .map((r) => r.id)
                .toSet();
        final toUpsert = serverGovernorates.where((g) => !dirtyIds.contains(g.id)).toList();
        await _db.batch(
          (batch) =>
              batch.insertAllOnConflictUpdate(_db.governoratesTable, toUpsert.map(_toCompanion).toList()),
        );

        final serverIds = serverGovernorates.map((g) => g.id).toSet();
        await (_db.update(_db.governoratesTable)
              ..where(
                (t) => t.id.isBiggerThanValue(0) & t.isDirty.equals(false) & t.id.isNotIn(serverIds),
              ))
            .write(const GovernoratesTableCompanion(isDeleted: Value(true)));
      });

  /// Tier 3 real delta application (design doc §6, row 8.6): [upserts] and
  /// [tombstoneIds] are exactly what the server says changed on this page —
  /// no absence inference, unlike [applyGovernoratesSnapshot]. Same
  /// dirty-row conflict policy applies to both upserts and tombstones: a row
  /// with a pending outbox entry is left untouched either way. Mirrors
  /// `GroupLocalDataSourceImpl.applyGroupChanges`.
  Future<void> applyGovernorateChanges({
    required List<Governorate> upserts,
    required List<int> tombstoneIds,
  }) =>
      _db.transaction(() async {
        final dirtyIds =
            (await (_db.select(_db.governoratesTable)..where((t) => t.isDirty.equals(true))).get())
                .map((r) => r.id)
                .toSet();

        final toUpsert = upserts.where((g) => !dirtyIds.contains(g.id)).toList();
        if (toUpsert.isNotEmpty) {
          await _db.batch(
            (batch) =>
                batch.insertAllOnConflictUpdate(_db.governoratesTable, toUpsert.map(_toCompanion).toList()),
          );
        }

        if (tombstoneIds.isNotEmpty) {
          await (_db.update(_db.governoratesTable)
                ..where((t) => t.id.isIn(tombstoneIds) & t.isDirty.equals(false)))
              .write(const GovernoratesTableCompanion(isDeleted: Value(true)));
        }
      });

  /// The stored Tier 3 watermark for Governorates (design doc §6, row 8.6).
  /// `0` (the backend's own "since the beginning" default) when never synced
  /// or when the stored value is somehow unparseable.
  Future<int> getGovernoratesSyncCursor() async {
    final row = await (_db.select(_db.syncStateTable)..where((t) => t.collection.equals(_syncCollection)))
        .getSingleOrNull();
    return int.tryParse(row?.cursor ?? '') ?? 0;
  }

  /// Persists the new watermark after a successful delta page. Only touches
  /// the `cursor` column — `lastSyncedAt` is written separately by
  /// `SyncService` once the whole pull cycle succeeds.
  Future<void> saveGovernoratesSyncCursor(int cursor) =>
      _db.into(_db.syncStateTable).insertOnConflictUpdate(
            SyncStateTableCompanion.insert(collection: _syncCollection, cursor: Value(cursor.toString())),
          );

  static const _syncCollection = 'governorates';

  Governorate _toEntity(GovernoratesTableData row) => Governorate(
        id: row.id,
        name: row.name,
        nameAr: row.nameAr,
        isLocked: row.isLocked,
        updatedAt: row.updatedAt,
      );

  GovernoratesTableCompanion _toCompanion(Governorate governorate, {bool isDirty = false}) =>
      GovernoratesTableCompanion.insert(
        id: Value(governorate.id),
        name: governorate.name,
        nameAr: Value(governorate.nameAr),
        isLocked: Value(governorate.isLocked),
        // `updatedAt` comes from the server (design doc §6, row 8.5/8.6);
        // still nullable because a locally-created draft (Tier 2 optimistic
        // create, not yet synced) has none. Never soft-deleted here.
        // `isDirty` defaults to false (a row that came from a confirmed
        // remote round trip) — callers queuing a Tier 2 optimistic write
        // pass `isDirty: true` explicitly.
        updatedAt: Value(governorate.updatedAt),
        isDeleted: const Value(false),
        isDirty: Value(isDirty),
      );
}
