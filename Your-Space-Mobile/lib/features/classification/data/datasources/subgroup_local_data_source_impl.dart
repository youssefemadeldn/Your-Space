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
  /// remote delete. Transitional Tier 1 write path; superseded by an
  /// outbox-driven soft-tombstone once row 8.15 lands.
  Future<void> deleteSubGroupLocal(int id) =>
      (_db.delete(_db.subGroupsTable)..where((t) => t.id.equals(id))).go();

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
        // callers queuing a Tier 2 optimistic write (row 8.15) pass
        // `isDirty: true` explicitly.
        isDeleted: const Value(false),
        isDirty: Value(isDirty),
      );
}
