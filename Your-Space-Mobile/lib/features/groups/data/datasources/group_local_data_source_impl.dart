import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/group.dart';

/// Drift-backed local store for Groups — the Tier 1 read path (CLAUDE.md
/// Architecture rule 7), mirrors `PersonLocalDataSourceImpl`. Does not
/// implement `BaseGroupDataSource`: it's typed concretely in
/// `GroupRepositoryImpl` so its `save*` write methods (no remote equivalent)
/// are reachable.
@Named('local')
@lazySingleton
class GroupLocalDataSourceImpl {
  final AppDatabase _db;

  GroupLocalDataSourceImpl(this._db);

  /// Reactive read path. `limit` grows as `loadMore()` is called on the
  /// caller side; this always queries from row 0 (no offset) rather than
  /// tracking a separate page window.
  Stream<List<Group>> watchGroups({String? search, required int limit}) {
    final query = _db.select(_db.groupsTable)
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
  Future<int> countGroups({String? search}) {
    final countExp = _db.groupsTable.id.count();
    final query = _db.selectOnly(_db.groupsTable)..addColumns([countExp]);
    query.where(_db.groupsTable.isDeleted.equals(false));
    if (search != null && search.isNotEmpty) {
      final pattern = '%$search%';
      query.where(_db.groupsTable.name.like(pattern) | _db.groupsTable.nameAr.like(pattern));
    }
    return query.map((row) => row.read(countExp) ?? 0).getSingle();
  }

  /// Tier 1 upsert, no tombstoning — kept as a documented primitive for a
  /// future caller that wants a plain bulk replace. `refreshGroups()`
  /// (Tier 3) uses `applyGroupsSnapshot` instead.
  Future<void> saveGroups(List<Group> groups) => _db.batch(
        (batch) => batch.insertAllOnConflictUpdate(
          _db.groupsTable,
          groups.map(_toCompanion).toList(),
        ),
      );

  /// No remote equivalent — single-row upsert after a successful
  /// create/update mutation. Superseded for Groups' own create/update path
  /// by the outbox (row 7.3) — kept as a documented primitive; still called
  /// transitionally from nowhere in production code once 7.3 lands, but
  /// costs nothing to leave in place (mirrors `PersonLocalDataSourceImpl`'s
  /// own `savePerson`).
  Future<void> saveGroup(Group group) =>
      _db.into(_db.groupsTable).insertOnConflictUpdate(_toCompanion(group));

  /// Tier 2 optimistic write (design doc §5): writes [group] into
  /// GroupsTable (marked dirty) and appends one OutboxTable row, in the
  /// same drift transaction. Returns the new outbox row's id so the
  /// repository's `createGroupAndSync` can ask `SyncService` to replay this
  /// specific row immediately.
  Future<int> queueGroupMutation({
    required Group group,
    required String operation, // 'create' | 'update'
    required String payloadJson,
  }) =>
      _db.transaction(() async {
        await _db.into(_db.groupsTable).insertOnConflictUpdate(
              _toCompanion(group, isDirty: true),
            );
        return _db.into(_db.outboxTable).insert(
              OutboxTableCompanion.insert(
                entityType: 'group',
                entityId: group.id,
                operation: operation,
                payloadJson: payloadJson,
              ),
            );
      });

  /// Called after a queued 'update' syncs successfully: overwrites the
  /// local row with the server-confirmed copy (clears `isDirty`) and
  /// removes the now-done outbox row, in one transaction.
  Future<void> confirmSyncedGroup(Group group, {required int replayedOutboxRowId}) =>
      _db.transaction(() async {
        await _db.into(_db.groupsTable).insertOnConflictUpdate(_toCompanion(group));
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();
      });

  /// Tier 2 temp-id reconciliation (design doc §5) after a queued 'create'
  /// syncs. One transaction:
  ///  1. insert the confirmed server row under [realGroup].id
  ///  2. delete the temp-id row
  ///  3. delete the just-replayed outbox row
  ///
  /// Unlike `PersonLocalDataSourceImpl.reconcileCreatedPerson`, no step 4
  /// (cross-entity FK-rewrite of other pending outbox rows referencing this
  /// tempId) is needed here — Groups' only analogous risk (a pending
  /// Person-create outbox row referencing a Group's tempId) is sidestepped
  /// by `GroupRepositoryImpl.createGroupAndSync`, which the wizard's inline
  /// "add new group" flow uses specifically to resolve the real id
  /// synchronously *before* building the person's own payload.
  Future<void> reconcileCreatedGroup({
    required int tempId,
    required Group realGroup,
    required int replayedOutboxRowId,
  }) =>
      _db.transaction(() async {
        await _db.into(_db.groupsTable).insertOnConflictUpdate(_toCompanion(realGroup));
        await (_db.delete(_db.groupsTable)..where((t) => t.id.equals(tempId))).go();
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();
      });

  /// Tier 3 "full refetch as delta" (design doc §6): [serverGroups] is the
  /// complete, just-fetched owned collection. Diffs it against local drift by
  /// id in one transaction:
  ///  - a row with `isDirty == true` is left untouched — it has a pending
  ///    outbox entry, so the local edit is presumed newer
  ///  - every other server row is upserted (clean: not dirty, not deleted)
  ///  - every local row with id > 0, isDirty == false, whose id is absent
  ///    from [serverGroups] is soft-tombstoned (`isDeleted = true`) — a
  ///    temp (negative) id is never a tombstone candidate; it was never on
  ///    the server to begin with
  Future<void> applyGroupsSnapshot(List<Group> serverGroups) => _db.transaction(() async {
        final dirtyIds = (await (_db.select(_db.groupsTable)..where((t) => t.isDirty.equals(true)))
                .get())
            .map((r) => r.id)
            .toSet();
        final toUpsert = serverGroups.where((g) => !dirtyIds.contains(g.id)).toList();
        await _db.batch(
          (batch) => batch.insertAllOnConflictUpdate(_db.groupsTable, toUpsert.map(_toCompanion).toList()),
        );

        final serverIds = serverGroups.map((g) => g.id).toSet();
        await (_db.update(_db.groupsTable)
              ..where(
                (t) => t.id.isBiggerThanValue(0) & t.isDirty.equals(false) & t.id.isNotIn(serverIds),
              ))
            .write(const GroupsTableCompanion(isDeleted: Value(true)));
      });

  Group _toEntity(GroupsTableData row) => Group(id: row.id, name: row.name, nameAr: row.nameAr);

  GroupsTableCompanion _toCompanion(Group group, {bool isDirty = false}) => GroupsTableCompanion.insert(
        id: Value(group.id),
        name: group.name,
        nameAr: Value(group.nameAr),
        // Backend doesn't expose `UpdatedAt` yet (design doc §6/§11 row 7.5).
        // Never soft-deleted here. `isDirty` defaults to false (a row that
        // came from a confirmed remote round trip) — callers queuing a
        // Tier 2 optimistic write pass `isDirty: true` explicitly.
        updatedAt: const Value(null),
        isDeleted: const Value(false),
        isDirty: Value(isDirty),
      );
}
