import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/neighborhood.dart';

/// Drift-backed local store for Neighborhoods — the Tier 1 read path
/// (CLAUDE.md Architecture rule 7), mirrors `CityLocalDataSourceImpl`. Does
/// not implement `BaseNeighborhoodDataSource`: it's typed concretely in
/// `NeighborhoodRepositoryImpl` so its `save*`/`deleteNeighborhoodLocal`
/// write methods (no direct remote equivalent) are reachable.
@Named('local')
@lazySingleton
class NeighborhoodLocalDataSourceImpl {
  final AppDatabase _db;

  NeighborhoodLocalDataSourceImpl(this._db);

  /// Reactive read path, scoped to one parent city — the local table holds
  /// *all* the user's neighborhoods; filtering by `cityId` is a plain
  /// `WHERE` clause (design doc §3), not a separate query per parent.
  Stream<List<Neighborhood>> watchNeighborhoods({required int cityId, String? search, required int limit}) {
    final query = _db.select(_db.neighborhoodsTable)
      ..where((t) => t.isDeleted.equals(false) & t.cityId.equals(cityId))
      ..orderBy([(t) => OrderingTerm.asc(t.name)])
      ..limit(limit);
    if (search != null && search.isNotEmpty) {
      final pattern = '%$search%';
      query.where((t) => t.name.like(pattern) | t.nameAr.like(pattern));
    }
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  /// Parent-agnostic reactive read — used by callers that don't have a city
  /// in hand yet; no known caller today, kept as a documented primitive
  /// alongside `watchNeighborhoods`.
  Stream<List<Neighborhood>> watchAllNeighborhoods({String? search, required int limit}) {
    final query = _db.select(_db.neighborhoodsTable)
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
  Future<int> countNeighborhoods({required int cityId, String? search}) {
    final countExp = _db.neighborhoodsTable.id.count();
    final query = _db.selectOnly(_db.neighborhoodsTable)..addColumns([countExp]);
    query.where(
      _db.neighborhoodsTable.isDeleted.equals(false) & _db.neighborhoodsTable.cityId.equals(cityId),
    );
    if (search != null && search.isNotEmpty) {
      final pattern = '%$search%';
      query.where(_db.neighborhoodsTable.name.like(pattern) | _db.neighborhoodsTable.nameAr.like(pattern));
    }
    return query.map((row) => row.read(countExp) ?? 0).getSingle();
  }

  /// Tier 1 upsert, no tombstoning — kept as a documented primitive for a
  /// future caller that wants a plain bulk replace. A future Tier 3 step's
  /// `refreshNeighborhoods()` will use a snapshot-apply method instead, same
  /// as `CityRepositoryImpl`'s own pattern.
  Future<void> saveNeighborhoods(List<Neighborhood> neighborhoods) => _db.batch(
        (batch) => batch.insertAllOnConflictUpdate(
          _db.neighborhoodsTable,
          neighborhoods.map(_toCompanion).toList(),
        ),
      );

  /// No remote equivalent — single-row upsert after a successful
  /// create/update mutation. This is the transitional Tier 1 write path used
  /// by `NeighborhoodRepositoryImpl.createNeighborhood`/`updateNeighborhood`
  /// until a later row moves them to the outbox (mirrors
  /// `CityLocalDataSourceImpl.saveCity`).
  Future<void> saveNeighborhood(Neighborhood neighborhood) =>
      _db.into(_db.neighborhoodsTable).insertOnConflictUpdate(_toCompanion(neighborhood));

  /// No remote equivalent — hard-removes the local row after a successful
  /// remote delete. Superseded for Neighborhood's own delete path by the
  /// outbox once it lands — kept as a documented primitive, mirrors
  /// `CityLocalDataSourceImpl.saveCity`'s own post-outbox retention.
  Future<void> deleteNeighborhoodLocal(int id) =>
      (_db.delete(_db.neighborhoodsTable)..where((t) => t.id.equals(id))).go();

  /// Tier 2 optimistic write (design doc §5): writes [neighborhood] into
  /// NeighborhoodsTable (marked dirty) and appends one OutboxTable row, in
  /// the same drift transaction. Returns the new outbox row's id so the
  /// repository's `createNeighborhoodAndSync` can ask `SyncService` to
  /// replay this specific row immediately. Mirrors
  /// `CityLocalDataSourceImpl.queueCityMutation`; unlike Governorate,
  /// Neighborhood has both `'create'` and `'update'` — see
  /// [queueDeletedNeighborhood] for the separate delete path.
  Future<int> queueNeighborhoodMutation({
    required Neighborhood neighborhood,
    required String operation, // 'create' | 'update'
    required String payloadJson,
  }) =>
      _db.transaction(() async {
        await _db.into(_db.neighborhoodsTable).insertOnConflictUpdate(
              _toCompanion(neighborhood, isDirty: true),
            );
        return _db.into(_db.outboxTable).insert(
              OutboxTableCompanion.insert(
                entityType: 'neighborhood',
                entityId: neighborhood.id,
                operation: operation,
                payloadJson: payloadJson,
              ),
            );
      });

  /// Called after a queued 'update' syncs successfully: overwrites the
  /// local row with the server-confirmed copy (clears `isDirty`) and
  /// removes the now-done outbox row, in one transaction. Mirrors
  /// `CityLocalDataSourceImpl.confirmSyncedCity`.
  Future<void> confirmSyncedNeighborhood(Neighborhood neighborhood, {required int replayedOutboxRowId}) =>
      _db.transaction(() async {
        await _db.into(_db.neighborhoodsTable).insertOnConflictUpdate(_toCompanion(neighborhood));
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();
      });

  /// Tier 2 temp-id reconciliation (design doc §5) after a queued 'create'
  /// syncs. One transaction:
  ///  1. insert the confirmed server row under [realNeighborhood].id
  ///  2. delete the temp-id row
  ///  3. delete the just-replayed outbox row
  ///
  /// Unlike `CityLocalDataSourceImpl.reconcileCreatedCity`, no step 4
  /// (dependent-table FK rewrite) is needed here — Neighborhood is the leaf
  /// of the location hierarchy, with no dependent entity of its own in Row 8
  /// (same as SubGroup's own `reconcileCreatedSubGroup`). Mirrors
  /// `SubGroupLocalDataSourceImpl.reconcileCreatedSubGroup`.
  Future<void> reconcileCreatedNeighborhood({
    required int tempId,
    required Neighborhood realNeighborhood,
    required int replayedOutboxRowId,
  }) =>
      _db.transaction(() async {
        await _db.into(_db.neighborhoodsTable).insertOnConflictUpdate(_toCompanion(realNeighborhood));
        await (_db.delete(_db.neighborhoodsTable)..where((t) => t.id.equals(tempId))).go();
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();
      });

  /// Tier 2 optimistic delete (design doc §5) — mirrors
  /// `CityLocalDataSourceImpl.queueDeletedCity` exactly. Two cases:
  ///  - [id] negative (a never-synced temp row, created and deleted offline
  ///    in the same session): the server has never heard of it, so just
  ///    remove the local row **and** its still-pending `'create'` outbox
  ///    row — no network round trip needed, ever.
  ///  - [id] positive (a real, previously-synced row): optimistically
  ///    tombstone it (`isDeleted: true`, `isDirty: true` — disappears from
  ///    `watchNeighborhoods` immediately via its existing
  ///    `isDeleted.equals(false)` filter) and append a `'delete'` outbox row
  ///    for `SyncService` to replay in the background. [payloadJson] carries
  ///    `cityId` — `NeighborhoodOutboxReplayer` needs it for
  ///    `BaseNeighborhoodDataSource.deleteNeighborhood`'s nested route, and
  ///    it isn't derivable from [id] alone.
  Future<void> queueDeletedNeighborhood(int id, {required String payloadJson}) => _db.transaction(() async {
        if (id < 0) {
          await (_db.delete(_db.neighborhoodsTable)..where((t) => t.id.equals(id))).go();
          await (_db.delete(_db.outboxTable)
                ..where((t) => t.entityType.equals('neighborhood') & t.entityId.equals(id)))
              .go();
          return;
        }
        await (_db.update(_db.neighborhoodsTable)..where((t) => t.id.equals(id)))
            .write(const NeighborhoodsTableCompanion(isDeleted: Value(true), isDirty: Value(true)));
        await _db.into(_db.outboxTable).insert(
              OutboxTableCompanion.insert(
                entityType: 'neighborhood',
                entityId: id,
                operation: 'delete',
                payloadJson: payloadJson,
              ),
            );
      });

  /// Called after a queued 'delete' syncs successfully: hard-removes the
  /// local row (the optimistic tombstone from [queueDeletedNeighborhood] is
  /// no longer needed once the server confirms it's gone) and removes the
  /// outbox row, in one transaction.
  Future<void> confirmDeletedNeighborhood(int id, {required int replayedOutboxRowId}) =>
      _db.transaction(() async {
        await (_db.delete(_db.neighborhoodsTable)..where((t) => t.id.equals(id))).go();
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();
      });

  /// Tier 3 "full refetch as delta" (design doc §6, row 8.22). [serverNeighborhoods]
  /// is the complete, just-fetched owned collection. Diffs it against local
  /// drift by id in one transaction:
  ///  - a row with `isDirty == true` is left untouched — it has a pending
  ///    outbox entry, so the local edit is presumed newer
  ///  - every other server row is upserted (clean: not dirty, not deleted)
  ///  - every local row with id > 0, isDirty == false, whose id is absent
  ///    from [serverNeighborhoods] is soft-tombstoned (`isDeleted = true`) —
  ///    a temp (negative) id is never a tombstone candidate; it was never on
  ///    the server to begin with
  /// Mirrors `CityLocalDataSourceImpl.applyCitiesSnapshot` exactly.
  Future<void> applyNeighborhoodsSnapshot(List<Neighborhood> serverNeighborhoods) => _db.transaction(() async {
        final dirtyIds = (await (_db.select(_db.neighborhoodsTable)..where((t) => t.isDirty.equals(true)))
                .get())
            .map((r) => r.id)
            .toSet();
        final toUpsert = serverNeighborhoods.where((n) => !dirtyIds.contains(n.id)).toList();
        await _db.batch(
          (batch) =>
              batch.insertAllOnConflictUpdate(_db.neighborhoodsTable, toUpsert.map(_toCompanion).toList()),
        );

        final serverIds = serverNeighborhoods.map((n) => n.id).toSet();
        await (_db.update(_db.neighborhoodsTable)
              ..where(
                (t) => t.id.isBiggerThanValue(0) & t.isDirty.equals(false) & t.id.isNotIn(serverIds),
              ))
            .write(const NeighborhoodsTableCompanion(isDeleted: Value(true)));
      });

  /// Tier 3 real delta application (design doc §6, row 8.24): [upserts] and
  /// [tombstoneIds] are exactly what the server says changed on this page —
  /// no absence inference, unlike [applyNeighborhoodsSnapshot]. Same
  /// dirty-row conflict policy applies to both upserts and tombstones: a row
  /// with a pending outbox entry is left untouched either way. Mirrors
  /// `CityLocalDataSourceImpl.applyCityChanges`.
  Future<void> applyNeighborhoodChanges({
    required List<Neighborhood> upserts,
    required List<int> tombstoneIds,
  }) =>
      _db.transaction(() async {
        final dirtyIds =
            (await (_db.select(_db.neighborhoodsTable)..where((t) => t.isDirty.equals(true))).get())
                .map((r) => r.id)
                .toSet();

        final toUpsert = upserts.where((n) => !dirtyIds.contains(n.id)).toList();
        if (toUpsert.isNotEmpty) {
          await _db.batch(
            (batch) =>
                batch.insertAllOnConflictUpdate(_db.neighborhoodsTable, toUpsert.map(_toCompanion).toList()),
          );
        }

        if (tombstoneIds.isNotEmpty) {
          await (_db.update(_db.neighborhoodsTable)
                ..where((t) => t.id.isIn(tombstoneIds) & t.isDirty.equals(false)))
              .write(const NeighborhoodsTableCompanion(isDeleted: Value(true)));
        }
      });

  /// The stored Tier 3 watermark for Neighborhoods (design doc §6, row
  /// 8.24). `0` (the backend's own "since the beginning" default) when
  /// never synced or when the stored value is somehow unparseable.
  Future<int> getNeighborhoodsSyncCursor() async {
    final row = await (_db.select(_db.syncStateTable)..where((t) => t.collection.equals(_syncCollection)))
        .getSingleOrNull();
    return int.tryParse(row?.cursor ?? '') ?? 0;
  }

  /// Persists the new watermark after a successful delta page. Only touches
  /// the `cursor` column — `lastSyncedAt` is written separately by
  /// `SyncService` once the whole pull cycle succeeds.
  Future<void> saveNeighborhoodsSyncCursor(int cursor) => _db.into(_db.syncStateTable).insertOnConflictUpdate(
        SyncStateTableCompanion.insert(collection: _syncCollection, cursor: Value(cursor.toString())),
      );

  static const _syncCollection = 'neighborhoods';

  Neighborhood _toEntity(NeighborhoodsTableData row) => Neighborhood(
        id: row.id,
        cityId: row.cityId,
        name: row.name,
        nameAr: row.nameAr,
        updatedAt: row.updatedAt,
      );

  NeighborhoodsTableCompanion _toCompanion(Neighborhood neighborhood, {bool isDirty = false}) =>
      NeighborhoodsTableCompanion.insert(
        id: Value(neighborhood.id),
        name: neighborhood.name,
        nameAr: Value(neighborhood.nameAr),
        cityId: neighborhood.cityId,
        // `updatedAt` comes from the server (design doc §6, row 8.23/8.24);
        // still nullable because a locally-created draft (Tier 2 optimistic
        // create, not yet synced) has none. Never soft-deleted here.
        // `isDirty` defaults to false (a row that came from a confirmed
        // remote round trip) — callers queuing a Tier 2 optimistic write
        // pass `isDirty: true` explicitly.
        updatedAt: Value(neighborhood.updatedAt),
        isDeleted: const Value(false),
        isDirty: Value(isDirty),
      );
}
