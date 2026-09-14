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
  /// remote delete. Superseded for City's own delete path by the outbox
  /// (row 8.9, [queueDeletedCity]/[confirmDeletedCity]) — kept as a
  /// documented primitive, mirrors `GovernorateLocalDataSourceImpl.
  /// saveGovernorate`'s own post-outbox retention.
  Future<void> deleteCityLocal(int id) =>
      (_db.delete(_db.citiesTable)..where((t) => t.id.equals(id))).go();

  /// Tier 2 optimistic write (design doc §5): writes [city] into CitiesTable
  /// (marked dirty) and appends one OutboxTable row, in the same drift
  /// transaction. Returns the new outbox row's id so the repository's
  /// `createCityAndSync` can ask `SyncService` to replay this specific row
  /// immediately. Mirrors `GroupLocalDataSourceImpl.queueGroupMutation`;
  /// unlike Governorate, City has both `'create'` and `'update'` — see
  /// [queueDeletedCity] for the separate delete path.
  Future<int> queueCityMutation({
    required City city,
    required String operation, // 'create' | 'update'
    required String payloadJson,
  }) =>
      _db.transaction(() async {
        await _db.into(_db.citiesTable).insertOnConflictUpdate(
              _toCompanion(city, isDirty: true),
            );
        return _db.into(_db.outboxTable).insert(
              OutboxTableCompanion.insert(
                entityType: 'city',
                entityId: city.id,
                operation: operation,
                payloadJson: payloadJson,
              ),
            );
      });

  /// Called after a queued 'update' syncs successfully: overwrites the
  /// local row with the server-confirmed copy (clears `isDirty`) and
  /// removes the now-done outbox row, in one transaction. Mirrors
  /// `GroupLocalDataSourceImpl.confirmSyncedGroup`.
  Future<void> confirmSyncedCity(City city, {required int replayedOutboxRowId}) =>
      _db.transaction(() async {
        await _db.into(_db.citiesTable).insertOnConflictUpdate(_toCompanion(city));
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();
      });

  /// Tier 2 temp-id reconciliation (design doc §5) after a queued 'create'
  /// syncs. One transaction:
  ///  1. insert the confirmed server row under [realCity].id
  ///  2. delete the temp-id row
  ///  3. delete the just-replayed outbox row
  ///  4. rewrite any dependent `NeighborhoodsTable` row (and any still-queued
  ///     `entityType='neighborhood'` outbox payload) that references [tempId]
  ///     — see row 8.21, Neighborhood's own Tier 2 step, which is what
  ///     actually adds this 4th step; nothing depends on City's temp id yet
  ///     at row 8.9. Mirrors `GroupLocalDataSourceImpl.reconcileCreatedGroup`.
  Future<void> reconcileCreatedCity({
    required int tempId,
    required City realCity,
    required int replayedOutboxRowId,
  }) =>
      _db.transaction(() async {
        await _db.into(_db.citiesTable).insertOnConflictUpdate(_toCompanion(realCity));
        await (_db.delete(_db.citiesTable)..where((t) => t.id.equals(tempId))).go();
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();
      });

  /// Tier 2 optimistic delete (design doc §5) — City is Row 8's first
  /// delete-through-outbox entity, so this shape is new (no precedent to
  /// mirror; both `GroupOutboxReplayer`/`PersonOutboxReplayer`'s `'delete'`
  /// branch is still the unimplemented "fails loudly" default). Two cases:
  ///  - [id] negative (a never-synced temp row, created and deleted offline
  ///    in the same session): the server has never heard of it, so just
  ///    remove the local row **and** its still-pending `'create'` outbox
  ///    row — no network round trip needed, ever.
  ///  - [id] positive (a real, previously-synced row): optimistically
  ///    tombstone it (`isDeleted: true`, `isDirty: true` — disappears from
  ///    `watchCities` immediately via its existing `isDeleted.equals(false)`
  ///    filter) and append a `'delete'` outbox row for `SyncService` to
  ///    replay in the background. [payloadJson] carries `governorateId` —
  ///    `CityOutboxReplayer` needs it for `BaseCityDataSource.deleteCity`'s
  ///    nested route, and it isn't derivable from [id] alone.
  Future<void> queueDeletedCity(int id, {required String payloadJson}) => _db.transaction(() async {
        if (id < 0) {
          await (_db.delete(_db.citiesTable)..where((t) => t.id.equals(id))).go();
          await (_db.delete(_db.outboxTable)
                ..where((t) => t.entityType.equals('city') & t.entityId.equals(id)))
              .go();
          return;
        }
        await (_db.update(_db.citiesTable)..where((t) => t.id.equals(id)))
            .write(const CitiesTableCompanion(isDeleted: Value(true), isDirty: Value(true)));
        await _db.into(_db.outboxTable).insert(
              OutboxTableCompanion.insert(
                entityType: 'city',
                entityId: id,
                operation: 'delete',
                payloadJson: payloadJson,
              ),
            );
      });

  /// Called after a queued 'delete' syncs successfully: hard-removes the
  /// local row (the optimistic tombstone from [queueDeletedCity] is no
  /// longer needed once the server confirms it's gone) and removes the
  /// outbox row, in one transaction.
  Future<void> confirmDeletedCity(int id, {required int replayedOutboxRowId}) => _db.transaction(() async {
        await (_db.delete(_db.citiesTable)..where((t) => t.id.equals(id))).go();
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();
      });

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
