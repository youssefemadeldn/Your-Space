import 'dart:convert';

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
  /// (Tier 3) uses `applyGroupChanges` (row 7.6) instead.
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
  ///  4. rewrite any dependent `SubGroupsTable` row (and any still-queued
  ///     `entityType='subgroup'` outbox payload) that references [tempId] —
  ///     the wizard's offline "add group, then immediately add subgroup
  ///     under it" chain (row 8.15, SubGroup's own Tier 2 step, which is
  ///     what actually adds this 4th step — SubGroup is Group's first real
  ///     dependent; nothing depended on Group's temp id before this row).
  ///     A subgroup outbox payload's `groupId` field is decoded, patched,
  ///     and re-encoded rather than string-replaced — `payloadJson` also
  ///     carries `name`/`nameAr`, which could coincidentally contain digits
  ///     matching [tempId] — mirrors `GovernorateLocalDataSourceImpl.
  ///     reconcileCreatedGovernorate`'s own row 8.9 addition.
  ///
  /// The person-create risk `PersonLocalDataSourceImpl.reconcileCreatedPerson`
  /// guards against doesn't apply symmetrically here: `GroupRepositoryImpl.
  /// createGroupAndSync` (used by the wizard's inline "add new group" flow)
  /// resolves the real id synchronously before a person payload embeds it,
  /// so no pending Person-create outbox row ever references a Group tempId.
  Future<void> reconcileCreatedGroup({
    required int tempId,
    required Group realGroup,
    required int replayedOutboxRowId,
  }) =>
      _db.transaction(() async {
        await _db.into(_db.groupsTable).insertOnConflictUpdate(_toCompanion(realGroup));
        await (_db.delete(_db.groupsTable)..where((t) => t.id.equals(tempId))).go();
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();

        await (_db.update(_db.subGroupsTable)..where((t) => t.groupId.equals(tempId)))
            .write(SubGroupsTableCompanion(groupId: Value(realGroup.id)));

        final pendingSubGroupRows = await (_db.select(_db.outboxTable)
              ..where((t) => t.entityType.equals('subgroup') & t.operation.equals('create')))
            .get();
        for (final row in pendingSubGroupRows) {
          final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
          if (payload['groupId'] != tempId) continue;
          payload['groupId'] = realGroup.id;
          await (_db.update(_db.outboxTable)..where((t) => t.id.equals(row.id)))
              .write(OutboxTableCompanion(payloadJson: Value(jsonEncode(payload))));
        }
      });

  /// Tier 3 "full refetch as delta" (design doc §6). No longer used by
  /// `GroupRepositoryImpl.refreshGroups()` since row 7.6 switched Groups to
  /// real deltas ([applyGroupChanges]) — kept as a documented full-snapshot
  /// primitive, mirrors `PersonLocalDataSourceImpl.applyPersonsSnapshot`.
  /// [serverGroups] is the complete, just-fetched owned collection. Diffs it
  /// against local drift by id in one transaction:
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

  /// Tier 3 real delta application (design doc §6, row 7.6): [upserts] and
  /// [tombstoneIds] are exactly what the server says changed on this page —
  /// no absence inference, unlike [applyGroupsSnapshot]. Same dirty-row
  /// conflict policy applies to both upserts and tombstones: a row with a
  /// pending outbox entry is left untouched either way. Mirrors
  /// `PersonLocalDataSourceImpl.applyPersonChanges`.
  Future<void> applyGroupChanges({
    required List<Group> upserts,
    required List<int> tombstoneIds,
  }) =>
      _db.transaction(() async {
        final dirtyIds = (await (_db.select(_db.groupsTable)..where((t) => t.isDirty.equals(true)))
                .get())
            .map((r) => r.id)
            .toSet();

        final toUpsert = upserts.where((g) => !dirtyIds.contains(g.id)).toList();
        if (toUpsert.isNotEmpty) {
          await _db.batch(
            (batch) => batch.insertAllOnConflictUpdate(_db.groupsTable, toUpsert.map(_toCompanion).toList()),
          );
        }

        if (tombstoneIds.isNotEmpty) {
          await (_db.update(_db.groupsTable)
                ..where((t) => t.id.isIn(tombstoneIds) & t.isDirty.equals(false)))
              .write(const GroupsTableCompanion(isDeleted: Value(true)));
        }
      });

  /// The stored Tier 3 watermark for Groups (design doc §6, row 7.6). `0`
  /// (the backend's own "since the beginning" default) when never synced or
  /// when the stored value is somehow unparseable.
  Future<int> getGroupsSyncCursor() async {
    final row = await (_db.select(_db.syncStateTable)..where((t) => t.collection.equals(_syncCollection)))
        .getSingleOrNull();
    return int.tryParse(row?.cursor ?? '') ?? 0;
  }

  /// Persists the new watermark after a successful delta page. Only touches
  /// the `cursor` column — `lastSyncedAt` is written separately by
  /// `SyncService` once the whole pull cycle succeeds.
  Future<void> saveGroupsSyncCursor(int cursor) => _db.into(_db.syncStateTable).insertOnConflictUpdate(
        SyncStateTableCompanion.insert(collection: _syncCollection, cursor: Value(cursor.toString())),
      );

  static const _syncCollection = 'groups';

  Group _toEntity(GroupsTableData row) =>
      Group(id: row.id, name: row.name, nameAr: row.nameAr, updatedAt: row.updatedAt);

  GroupsTableCompanion _toCompanion(Group group, {bool isDirty = false}) => GroupsTableCompanion.insert(
        id: Value(group.id),
        name: group.name,
        nameAr: Value(group.nameAr),
        // `updatedAt` comes from the server (design doc §6, row 7.5/7.6);
        // still nullable because a locally-created draft (Tier 2 optimistic
        // create, not yet synced) has none. Never soft-deleted here.
        // `isDirty` defaults to false (a row that came from a confirmed
        // remote round trip) — callers queuing a Tier 2 optimistic write
        // pass `isDirty: true` explicitly.
        updatedAt: Value(group.updatedAt),
        isDeleted: const Value(false),
        isDirty: Value(isDirty),
      );
}
