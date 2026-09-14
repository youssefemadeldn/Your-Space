import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/city.dart';

/// Drift-backed local store for Cities — the Tier 1 read path (CLAUDE.md
/// Architecture rule 7), mirrors `GovernorateLocalDataSourceImpl`. Does not
/// implement `BaseCityDataSource`: it's typed concretely in
/// `CityRepositoryImpl` so its `save*`/`deleteCityLocal` write methods (no
/// direct remote equivalent) are reachable.
@Named('local')
@lazySingleton
class CityLocalDataSourceImpl {
  final AppDatabase _db;

  CityLocalDataSourceImpl(this._db);

  /// Reactive read path, scoped to one parent governorate — the local table
  /// holds *all* the user's cities; filtering by `governorateId` is a plain
  /// `WHERE` clause (design doc §3), not a separate query per parent.
  Stream<List<City>> watchCities({required int governorateId, String? search, required int limit}) {
    final query = _db.select(_db.citiesTable)
      ..where((t) => t.isDeleted.equals(false) & t.governorateId.equals(governorateId))
      ..orderBy([(t) => OrderingTerm.asc(t.name)])
      ..limit(limit);
    if (search != null && search.isNotEmpty) {
      final pattern = '%$search%';
      query.where((t) => t.name.like(pattern) | t.nameAr.like(pattern));
    }
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  /// Parent-agnostic reactive read — used by callers that don't have a
  /// governorate in hand yet (e.g. a future flat city picker); no known
  /// caller today, kept as a documented primitive alongside `watchCities`.
  Stream<List<City>> watchAllCities({String? search, required int limit}) {
    final query = _db.select(_db.citiesTable)
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
  Future<int> countCities({required int governorateId, String? search}) {
    final countExp = _db.citiesTable.id.count();
    final query = _db.selectOnly(_db.citiesTable)..addColumns([countExp]);
    query.where(_db.citiesTable.isDeleted.equals(false) & _db.citiesTable.governorateId.equals(governorateId));
    if (search != null && search.isNotEmpty) {
      final pattern = '%$search%';
      query.where(_db.citiesTable.name.like(pattern) | _db.citiesTable.nameAr.like(pattern));
    }
    return query.map((row) => row.read(countExp) ?? 0).getSingle();
  }

  /// Tier 1 upsert, no tombstoning — kept as a documented primitive for a
  /// future caller that wants a plain bulk replace. `refreshCities()`
  /// (Tier 3, row 8.10) uses `applyCitiesSnapshot` instead.
  Future<void> saveCities(List<City> cities) => _db.batch(
        (batch) => batch.insertAllOnConflictUpdate(
          _db.citiesTable,
          cities.map(_toCompanion).toList(),
        ),
      );

  /// No remote equivalent — single-row upsert after a successful
  /// create/update mutation. This is the transitional Tier 1 write path used
  /// by `CityRepositoryImpl.createCity`/`updateCity` until row 8.9 moves
  /// them to the outbox (mirrors `GovernorateLocalDataSourceImpl.
  /// saveGovernorate`).
  Future<void> saveCity(City city) =>
      _db.into(_db.citiesTable).insertOnConflictUpdate(_toCompanion(city));

  /// No remote equivalent — hard-removes the local row after a successful
  /// remote delete. Transitional Tier 1 write path (design doc §3 has no
  /// tombstone concept yet — that's Tier 3); superseded by an outbox-driven
  /// soft-tombstone once row 8.9 lands.
  Future<void> deleteCityLocal(int id) =>
      (_db.delete(_db.citiesTable)..where((t) => t.id.equals(id))).go();

  City _toEntity(CitiesTableData row) => City(
        id: row.id,
        governorateId: row.governorateId,
        name: row.name,
        nameAr: row.nameAr,
      );

  CitiesTableCompanion _toCompanion(City city, {bool isDirty = false}) => CitiesTableCompanion.insert(
        id: Value(city.id),
        name: city.name,
        nameAr: Value(city.nameAr),
        governorateId: city.governorateId,
        // `updatedAt` is added once the backend exposes it (row 8.11/8.12) —
        // nothing to set yet. Never soft-deleted here. `isDirty` defaults to
        // false (a row that came from a confirmed remote round trip) —
        // callers queuing a Tier 2 optimistic write (row 8.9) pass
        // `isDirty: true` explicitly.
        isDeleted: const Value(false),
        isDirty: Value(isDirty),
      );
}
