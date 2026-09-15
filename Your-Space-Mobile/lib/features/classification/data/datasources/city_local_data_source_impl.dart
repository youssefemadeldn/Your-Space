import 'dart:convert';

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
  ///     `entityType='neighborhood'` outbox payload) that references
  ///     [tempId] — City is Group's peer as a real parent here (row 8.21,
  ///     Neighborhood's own Tier 2 step; SubGroup's equivalent landed for
  ///     Group at row 8.15). Mirrors
  ///     `GovernorateLocalDataSourceImpl.reconcileCreatedGovernorate`'s own
  ///     4th step (decode/patch/re-encode, never string-replace — avoids
  ///     corrupting a `name`/`nameAr` field that could coincidentally
  ///     contain the tempId's digits).
  Future<void> reconcileCreatedCity({
    required int tempId,
    required City realCity,
    required int replayedOutboxRowId,
  }) =>
      _db.transaction(() async {
        await _db.into(_db.citiesTable).insertOnConflictUpdate(_toCompanion(realCity));
        await (_db.delete(_db.citiesTable)..where((t) => t.id.equals(tempId))).go();
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();

        await (_db.update(_db.neighborhoodsTable)..where((t) => t.cityId.equals(tempId)))
            .write(NeighborhoodsTableCompanion(cityId: Value(realCity.id)));

        final pendingNeighborhoodRows = await (_db.select(_db.outboxTable)
              ..where((t) => t.entityType.equals('neighborhood') & t.operation.equals('create')))
            .get();
        for (final row in pendingNeighborhoodRows) {
          final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
          if (payload['cityId'] != tempId) continue;
          payload['cityId'] = realCity.id;
          await (_db.update(_db.outboxTable)..where((t) => t.id.equals(row.id)))
              .write(OutboxTableCompanion(payloadJson: Value(jsonEncode(payload))));
        }
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

  /// Tier 3 "full refetch as delta" (design doc §6, row 8.10) — City has no
  /// backend `since`/cursor support yet (that's 8.11/8.12), so
  /// `refreshCities()` fetches the complete, just-fetched owned collection
  /// and diffs it against local drift by id in one transaction:
  ///  - a row with `isDirty == true` is left untouched — it has a pending
  ///    outbox entry, so the local edit is presumed newer
  ///  - every other server row is upserted (clean: not dirty, not deleted)
  ///  - every local row with id > 0, isDirty == false, whose id is absent
  ///    from [serverCities] is soft-tombstoned (`isDeleted = true`) — a temp
  ///    (negative) id is never a tombstone candidate; it was never on the
  ///    server to begin with
  ///
  /// Mirrors `GovernorateLocalDataSourceImpl.applyGovernoratesSnapshot`.
  Future<void> applyCitiesSnapshot(List<City> serverCities) => _db.transaction(() async {
        final dirtyIds =
            (await (_db.select(_db.citiesTable)..where((t) => t.isDirty.equals(true))).get())
                .map((r) => r.id)
                .toSet();
        final toUpsert = serverCities.where((c) => !dirtyIds.contains(c.id)).toList();
        await _db.batch(
          (batch) => batch.insertAllOnConflictUpdate(_db.citiesTable, toUpsert.map(_toCompanion).toList()),
        );

        final serverIds = serverCities.map((c) => c.id).toSet();
        await (_db.update(_db.citiesTable)
              ..where(
                (t) => t.id.isBiggerThanValue(0) & t.isDirty.equals(false) & t.id.isNotIn(serverIds),
              ))
            .write(const CitiesTableCompanion(isDeleted: Value(true)));
      });

  /// Tier 3 real delta application (design doc §6, row 8.12): [upserts] and
  /// [tombstoneIds] are exactly what the server says changed on this page —
  /// no absence inference, unlike [applyCitiesSnapshot]. Same dirty-row
  /// conflict policy applies to both upserts and tombstones: a row with a
  /// pending outbox entry is left untouched either way. Mirrors
  /// `GovernorateLocalDataSourceImpl.applyGovernorateChanges`.
  Future<void> applyCityChanges({
    required List<City> upserts,
    required List<int> tombstoneIds,
  }) =>
      _db.transaction(() async {
        final dirtyIds =
            (await (_db.select(_db.citiesTable)..where((t) => t.isDirty.equals(true))).get())
                .map((r) => r.id)
                .toSet();

        final toUpsert = upserts.where((c) => !dirtyIds.contains(c.id)).toList();
        if (toUpsert.isNotEmpty) {
          await _db.batch(
            (batch) => batch.insertAllOnConflictUpdate(_db.citiesTable, toUpsert.map(_toCompanion).toList()),
          );
        }

        if (tombstoneIds.isNotEmpty) {
          await (_db.update(_db.citiesTable)
                ..where((t) => t.id.isIn(tombstoneIds) & t.isDirty.equals(false)))
              .write(const CitiesTableCompanion(isDeleted: Value(true)));
        }
      });

  /// The stored Tier 3 watermark for Cities (design doc §6, row 8.12). `0`
  /// (the backend's own "since the beginning" default) when never synced or
  /// when the stored value is somehow unparseable.
  Future<int> getCitiesSyncCursor() async {
    final row = await (_db.select(_db.syncStateTable)..where((t) => t.collection.equals(_syncCollection)))
        .getSingleOrNull();
    return int.tryParse(row?.cursor ?? '') ?? 0;
  }

  /// Persists the new watermark after a successful delta page. Only touches
  /// the `cursor` column — `lastSyncedAt` is written separately by
  /// `SyncService` once the whole pull cycle succeeds.
  Future<void> saveCitiesSyncCursor(int cursor) => _db.into(_db.syncStateTable).insertOnConflictUpdate(
        SyncStateTableCompanion.insert(collection: _syncCollection, cursor: Value(cursor.toString())),
      );

  static const _syncCollection = 'cities';

  City _toEntity(CitiesTableData row) => City(
        id: row.id,
        governorateId: row.governorateId,
        name: row.name,
        nameAr: row.nameAr,
        updatedAt: row.updatedAt,
      );

  CitiesTableCompanion _toCompanion(City city, {bool isDirty = false}) => CitiesTableCompanion.insert(
        id: Value(city.id),
        name: city.name,
        nameAr: Value(city.nameAr),
        governorateId: city.governorateId,
        // `updatedAt` comes from the server (design doc §6, row 8.11/8.12);
        // still nullable because a locally-created draft (Tier 2 optimistic
        // create, not yet synced) has none. Never soft-deleted here.
        // `isDirty` defaults to false (a row that came from a confirmed
        // remote round trip) — callers queuing a Tier 2 optimistic write
        // (row 8.9) pass `isDirty: true` explicitly.
        updatedAt: Value(city.updatedAt),
        isDeleted: const Value(false),
        isDirty: Value(isDirty),
      );
}
