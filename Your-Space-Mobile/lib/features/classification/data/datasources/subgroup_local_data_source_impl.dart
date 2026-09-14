import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/subgroup.dart';

/// Drift-backed local store for SubGroups — the Tier 1 read path (CLAUDE.md
/// Architecture rule 7), mirrors `CityLocalDataSourceImpl`. Does not
/// implement `BaseSubGroupDataSource`: it's typed concretely in
/// `SubGroupRepositoryImpl` so its `save*`/`deleteSubGroupLocal` write
/// methods (no direct remote equivalent) are reachable.
@Named('local')
@lazySingleton
class SubGroupLocalDataSourceImpl {
  final AppDatabase _db;

  SubGroupLocalDataSourceImpl(this._db);

  /// Reactive read path, scoped to one parent group — the local table holds
  /// *all* the user's subgroups; filtering by `groupId` is a plain `WHERE`
  /// clause (design doc §3), not a separate query per parent.
  Stream<List<SubGroup>> watchSubGroups({required int groupId, String? search, required int limit}) {
    final query = _db.select(_db.subGroupsTable)
      ..where((t) => t.isDeleted.equals(false) & t.groupId.equals(groupId))
      ..orderBy([(t) => OrderingTerm.asc(t.name)])
      ..limit(limit);
    if (search != null && search.isNotEmpty) {
      final pattern = '%$search%';
      query.where((t) => t.name.like(pattern) | t.nameAr.like(pattern));
    }
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  /// Parent-agnostic reactive read — used by callers that don't have a
  /// group in hand yet; no known caller today, kept as a documented
  /// primitive alongside `watchSubGroups`.
  Stream<List<SubGroup>> watchAllSubGroups({String? search, required int limit}) {
    final query = _db.select(_db.subGroupsTable)
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
  Future<int> countSubGroups({required int groupId, String? search}) {
    final countExp = _db.subGroupsTable.id.count();
    final query = _db.selectOnly(_db.subGroupsTable)..addColumns([countExp]);
    query.where(_db.subGroupsTable.isDeleted.equals(false) & _db.subGroupsTable.groupId.equals(groupId));
    if (search != null && search.isNotEmpty) {
      final pattern = '%$search%';
      query.where(_db.subGroupsTable.name.like(pattern) | _db.subGroupsTable.nameAr.like(pattern));
    }
    return query.map((row) => row.read(countExp) ?? 0).getSingle();
  }

  /// Tier 1 upsert, no tombstoning — kept as a documented primitive for a
  /// future caller that wants a plain bulk replace. `refreshSubGroups()`
  /// (Tier 3, row 8.16) uses `applySubGroupsSnapshot` instead.
  Future<void> saveSubGroups(List<SubGroup> subGroups) => _db.batch(
        (batch) => batch.insertAllOnConflictUpdate(
          _db.subGroupsTable,
          subGroups.map(_toCompanion).toList(),
        ),
      );

  /// No remote equivalent — single-row upsert after a successful
  /// create/update mutation. This is the transitional Tier 1 write path used
  /// by `SubGroupRepositoryImpl.createSubGroup`/`updateSubGroup` until row
  /// 8.15 moves them to the outbox (mirrors `CityLocalDataSourceImpl.saveCity`).
  Future<void> saveSubGroup(SubGroup subGroup) =>
      _db.into(_db.subGroupsTable).insertOnConflictUpdate(_toCompanion(subGroup));

  /// No remote equivalent — hard-removes the local row after a successful
  /// remote delete. Superseded for SubGroup's own delete path by the outbox
  /// (row 8.15, [queueDeletedSubGroup]/[confirmDeletedSubGroup]) — kept as a
  /// documented primitive, mirrors `CityLocalDataSourceImpl.saveCity`'s own
  /// post-outbox retention.
  Future<void> deleteSubGroupLocal(int id) =>
      (_db.delete(_db.subGroupsTable)..where((t) => t.id.equals(id))).go();

  /// Tier 2 optimistic write (design doc §5): writes [subGroup] into
  /// SubGroupsTable (marked dirty) and appends one OutboxTable row, in the
  /// same drift transaction. Returns the new outbox row's id so the
  /// repository's `createSubGroupAndSync` can ask `SyncService` to replay
  /// this specific row immediately. Mirrors `CityLocalDataSourceImpl.
  /// queueCityMutation`; unlike Governorate, SubGroup has both `'create'`
  /// and `'update'` — see [queueDeletedSubGroup] for the separate delete path.
  Future<int> queueSubGroupMutation({
    required SubGroup subGroup,
    required String operation, // 'create' | 'update'
    required String payloadJson,
  }) =>
      _db.transaction(() async {
        await _db.into(_db.subGroupsTable).insertOnConflictUpdate(
              _toCompanion(subGroup, isDirty: true),
            );
        return _db.into(_db.outboxTable).insert(
              OutboxTableCompanion.insert(
                entityType: 'subgroup',
                entityId: subGroup.id,
                operation: operation,
                payloadJson: payloadJson,
              ),
            );
      });

  /// Called after a queued 'update' syncs successfully: overwrites the
  /// local row with the server-confirmed copy (clears `isDirty`) and
  /// removes the now-done outbox row, in one transaction. Mirrors
  /// `CityLocalDataSourceImpl.confirmSyncedCity`.
  Future<void> confirmSyncedSubGroup(SubGroup subGroup, {required int replayedOutboxRowId}) =>
      _db.transaction(() async {
        await _db.into(_db.subGroupsTable).insertOnConflictUpdate(_toCompanion(subGroup));
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();
      });

  /// Tier 2 temp-id reconciliation (design doc §5) after a queued 'create'
  /// syncs. One transaction:
  ///  1. insert the confirmed server row under [realSubGroup].id
  ///  2. delete the temp-id row
  ///  3. delete the just-replayed outbox row
  ///
  /// Unlike `CityLocalDataSourceImpl.reconcileCreatedCity`, no step 4
  /// (dependent-table FK rewrite) is needed here — SubGroup has no
  /// dependent entity of its own in Row 8 (it's a leaf, same as Governorate
  /// before City existed). Mirrors `GroupLocalDataSourceImpl.
  /// reconcileCreatedGroup`'s own pre-8.15 shape.
  Future<void> reconcileCreatedSubGroup({
    required int tempId,
    required SubGroup realSubGroup,
    required int replayedOutboxRowId,
  }) =>
      _db.transaction(() async {
        await _db.into(_db.subGroupsTable).insertOnConflictUpdate(_toCompanion(realSubGroup));
        await (_db.delete(_db.subGroupsTable)..where((t) => t.id.equals(tempId))).go();
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
  ///    `watchSubGroups` immediately via its existing
  ///    `isDeleted.equals(false)` filter) and append a `'delete'` outbox row
  ///    for `SyncService` to replay in the background. [payloadJson] carries
  ///    `groupId` — `SubGroupOutboxReplayer` needs it for
  ///    `BaseSubGroupDataSource.deleteSubGroup`'s nested route, and it isn't
  ///    derivable from [id] alone.
  Future<void> queueDeletedSubGroup(int id, {required String payloadJson}) => _db.transaction(() async {
        if (id < 0) {
          await (_db.delete(_db.subGroupsTable)..where((t) => t.id.equals(id))).go();
          await (_db.delete(_db.outboxTable)
                ..where((t) => t.entityType.equals('subgroup') & t.entityId.equals(id)))
              .go();
          return;
        }
        await (_db.update(_db.subGroupsTable)..where((t) => t.id.equals(id)))
            .write(const SubGroupsTableCompanion(isDeleted: Value(true), isDirty: Value(true)));
        await _db.into(_db.outboxTable).insert(
              OutboxTableCompanion.insert(
                entityType: 'subgroup',
                entityId: id,
                operation: 'delete',
                payloadJson: payloadJson,
              ),
            );
      });

  /// Called after a queued 'delete' syncs successfully: hard-removes the
  /// local row (the optimistic tombstone from [queueDeletedSubGroup] is no
  /// longer needed once the server confirms it's gone) and removes the
  /// outbox row, in one transaction.
  Future<void> confirmDeletedSubGroup(int id, {required int replayedOutboxRowId}) => _db.transaction(() async {
        await (_db.delete(_db.subGroupsTable)..where((t) => t.id.equals(id))).go();
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();
      });

  SubGroup _toEntity(SubGroupsTableData row) => SubGroup(
        id: row.id,
        groupId: row.groupId,
        name: row.name,
        nameAr: row.nameAr,
      );

  SubGroupsTableCompanion _toCompanion(SubGroup subGroup, {bool isDirty = false}) => SubGroupsTableCompanion.insert(
        id: Value(subGroup.id),
        name: subGroup.name,
        nameAr: Value(subGroup.nameAr),
        groupId: subGroup.groupId,
        // `updatedAt` is added once the backend exposes it (row 8.17/8.18) —
        // nothing to set yet. Never soft-deleted here. `isDirty` defaults to
        // false (a row that came from a confirmed remote round trip) —
        // callers queuing a Tier 2 optimistic write pass `isDirty: true`
        // explicitly.
        isDeleted: const Value(false),
        isDirty: Value(isDirty),
      );
}
