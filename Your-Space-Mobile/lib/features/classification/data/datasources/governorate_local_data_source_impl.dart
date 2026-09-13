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
  /// future caller that wants a plain bulk replace. Row 8.4/8.6's
  /// `refreshGovernorates()` uses `applyGovernorateChanges`/
  /// `applyGovernoratesSnapshot` instead.
  Future<void> saveGovernorates(List<Governorate> governorates) => _db.batch(
        (batch) => batch.insertAllOnConflictUpdate(
          _db.governoratesTable,
          governorates.map(_toCompanion).toList(),
        ),
      );

  /// No remote equivalent — single-row upsert after a successful
  /// create mutation. This is the transitional Tier 1 write path used by
  /// `GovernorateRepositoryImpl.createGovernorate` until row 8.3 moves it to
  /// the outbox (mirrors `GroupLocalDataSourceImpl.saveGroup`).
  Future<void> saveGovernorate(Governorate governorate) =>
      _db.into(_db.governoratesTable).insertOnConflictUpdate(_toCompanion(governorate));

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
  /// Not called by `GovernorateRepositoryImpl` yet — wired up by row 8.4's
  /// `refreshGovernorates()`, same sequencing as `GroupLocalDataSourceImpl.
  /// applyGroupsSnapshot` in row 7.2.
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

  Governorate _toEntity(GovernoratesTableData row) => Governorate(
        id: row.id,
        name: row.name,
        nameAr: row.nameAr,
        isLocked: row.isLocked,
      );

  GovernoratesTableCompanion _toCompanion(Governorate governorate) => GovernoratesTableCompanion.insert(
        id: Value(governorate.id),
        name: governorate.name,
        nameAr: Value(governorate.nameAr),
        isLocked: Value(governorate.isLocked),
        // `updatedAt` is added once the backend exposes it (row 8.5/8.6) —
        // nothing to set yet. Never soft-deleted here; `isDirty` defaults to
        // false (a row that came from a confirmed remote round trip).
        isDeleted: const Value(false),
        isDirty: const Value(false),
      );
}
