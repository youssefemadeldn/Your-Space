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

  Neighborhood _toEntity(NeighborhoodsTableData row) => Neighborhood(
        id: row.id,
        cityId: row.cityId,
        name: row.name,
        nameAr: row.nameAr,
      );

  NeighborhoodsTableCompanion _toCompanion(Neighborhood neighborhood) => NeighborhoodsTableCompanion.insert(
        id: Value(neighborhood.id),
        name: neighborhood.name,
        nameAr: Value(neighborhood.nameAr),
        cityId: neighborhood.cityId,
        // `updatedAt` is populated once delta sync lands for Neighborhood —
        // nothing to set yet at Tier 1. Never soft-deleted here. `isDirty`
        // defaults to false (Tier 2 outbox isn't wired for Neighborhood yet).
        isDeleted: const Value(false),
      );
}
