import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/neighborhood.dart';
import 'package:your_space_mobile/features/classification/data/datasources/neighborhood_local_data_source_impl.dart';

void main() {
  late AppDatabase database;
  late NeighborhoodLocalDataSourceImpl dataSource;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dataSource = NeighborhoodLocalDataSourceImpl(database);
  });

  tearDown(() => database.close());

  test('watchNeighborhoods emits the seeded set and reacts to a later saveNeighborhood call', () async {
    await dataSource.saveNeighborhoods(const [
      Neighborhood(id: 1, cityId: 7, name: 'Zamalek'),
      Neighborhood(id: 2, cityId: 7, name: 'Sarayat'),
    ]);

    final emissions = <List<Neighborhood>>[];
    final subscription = dataSource.watchNeighborhoods(cityId: 7, limit: 10).listen(emissions.add);
    addTearDown(subscription.cancel);

    await pumpEventQueue();
    expect(emissions, hasLength(1));
    expect(
      emissions.single,
      containsAll(const [
        Neighborhood(id: 1, cityId: 7, name: 'Zamalek'),
        Neighborhood(id: 2, cityId: 7, name: 'Sarayat'),
      ]),
    );

    await dataSource.saveNeighborhood(const Neighborhood(id: 3, cityId: 7, name: 'Mohandessin'));
    await pumpEventQueue();

    expect(emissions.last, hasLength(3));
  });

  test('watchNeighborhoods filters strictly by cityId', () async {
    await dataSource.saveNeighborhoods(const [
      Neighborhood(id: 1, cityId: 7, name: 'Zamalek'),
      Neighborhood(id: 2, cityId: 8, name: 'Sarayat'),
    ]);

    final neighborhoods = await dataSource.watchNeighborhoods(cityId: 7, limit: 10).first;

    expect(neighborhoods.map((n) => n.id), [1]);
  });

  test('watchAllNeighborhoods is parent-agnostic', () async {
    await dataSource.saveNeighborhoods(const [
      Neighborhood(id: 1, cityId: 7, name: 'Zamalek'),
      Neighborhood(id: 2, cityId: 8, name: 'Sarayat'),
    ]);

    final neighborhoods = await dataSource.watchAllNeighborhoods(limit: 10).first;

    expect(neighborhoods.map((n) => n.id), containsAll([1, 2]));
  });

  test('saveNeighborhood upserts rather than duplicates an existing id', () async {
    await dataSource.saveNeighborhood(const Neighborhood(id: 1, cityId: 7, name: 'Zamalek'));
    await dataSource.saveNeighborhood(const Neighborhood(id: 1, cityId: 7, name: 'Zamalek (Renamed)'));

    final neighborhoods = await dataSource.watchNeighborhoods(cityId: 7, limit: 10).first;

    expect(neighborhoods, const [Neighborhood(id: 1, cityId: 7, name: 'Zamalek (Renamed)')]);
  });

  test('search matches name and nameAr independently', () async {
    await dataSource.saveNeighborhoods(const [
      Neighborhood(id: 1, cityId: 7, name: 'Zamalek', nameAr: 'الزمالك'),
      Neighborhood(id: 2, cityId: 7, name: 'Sarayat'),
    ]);

    expect(
      (await dataSource.watchNeighborhoods(cityId: 7, search: 'zamalek', limit: 10).first).map((n) => n.id),
      [1],
    );
    expect(
      (await dataSource.watchNeighborhoods(cityId: 7, search: 'الزمالك', limit: 10).first).map((n) => n.id),
      [1],
    );
    expect(
      (await dataSource.watchNeighborhoods(cityId: 7, search: 'saray', limit: 10).first).map((n) => n.id),
      [2],
    );
  });

  test('limit truncates the result set', () async {
    await dataSource.saveNeighborhoods(
      [for (var i = 1; i <= 5; i++) Neighborhood(id: i, cityId: 7, name: 'Neighborhood $i')],
    );

    final neighborhoods = await dataSource.watchNeighborhoods(cityId: 7, limit: 2).first;

    expect(neighborhoods, hasLength(2));
  });

  test('countNeighborhoods matches the unlimited watchNeighborhoods length and respects search', () async {
    await dataSource.saveNeighborhoods(const [
      Neighborhood(id: 1, cityId: 7, name: 'Zamalek'),
      Neighborhood(id: 2, cityId: 7, name: 'Sarayat'),
      Neighborhood(id: 3, cityId: 7, name: 'Book club'),
    ]);

    expect(await dataSource.countNeighborhoods(cityId: 7), 3);
    expect(await dataSource.countNeighborhoods(cityId: 7, search: 'club'), 1);
  });

  test('deleteNeighborhoodLocal hard-removes the row', () async {
    await dataSource.saveNeighborhood(const Neighborhood(id: 1, cityId: 7, name: 'Zamalek'));

    await dataSource.deleteNeighborhoodLocal(1);

    final neighborhoods = await dataSource.watchNeighborhoods(cityId: 7, limit: 10).first;
    expect(neighborhoods, isEmpty);
  });

  test('queueNeighborhoodMutation writes a dirty row and appends one outbox row', () async {
    final rowId = await dataSource.queueNeighborhoodMutation(
      neighborhood: const Neighborhood(id: -1, cityId: 7, name: 'Book club'),
      operation: 'create',
      payloadJson: '{"cityId":7,"name":"Book club"}',
    );

    final neighborhoods = await dataSource.watchNeighborhoods(cityId: 7, limit: 10).first;
    expect(neighborhoods.single.name, 'Book club');
    final outboxRows = await database.select(database.outboxTable).get();
    expect(outboxRows.single.id, rowId);
    expect(outboxRows.single.entityType, 'neighborhood');
    expect(outboxRows.single.operation, 'create');
  });

  test('confirmSyncedNeighborhood overwrites the row and removes the outbox row', () async {
    final rowId = await dataSource.queueNeighborhoodMutation(
      neighborhood: const Neighborhood(id: 1, cityId: 7, name: 'Zamalek'),
      operation: 'update',
      payloadJson: '{}',
    );

    await dataSource.confirmSyncedNeighborhood(
      const Neighborhood(id: 1, cityId: 7, name: 'Zamalek (Confirmed)'),
      replayedOutboxRowId: rowId,
    );

    final neighborhoods = await dataSource.watchNeighborhoods(cityId: 7, limit: 10).first;
    expect(neighborhoods.single.name, 'Zamalek (Confirmed)');
    expect(await database.select(database.outboxTable).get(), isEmpty);
  });

  test('reconcileCreatedNeighborhood swaps the temp id for the real one and clears the outbox row', () async {
    final rowId = await dataSource.queueNeighborhoodMutation(
      neighborhood: const Neighborhood(id: -42, cityId: 7, name: 'Book club'),
      operation: 'create',
      payloadJson: '{}',
    );

    await dataSource.reconcileCreatedNeighborhood(
      tempId: -42,
      realNeighborhood: const Neighborhood(id: 5, cityId: 7, name: 'Book club'),
      replayedOutboxRowId: rowId,
    );

    final neighborhoods = await dataSource.watchNeighborhoods(cityId: 7, limit: 10).first;
    expect(neighborhoods.map((n) => n.id), [5]);
    expect(await database.select(database.outboxTable).get(), isEmpty);
  });

  group('queueDeletedNeighborhood', () {
    test('a real (positive) id is soft-tombstoned and queued for the outbox', () async {
      await dataSource.saveNeighborhood(const Neighborhood(id: 1, cityId: 7, name: 'Zamalek'));

      await dataSource.queueDeletedNeighborhood(1, payloadJson: '{"cityId":7}');

      final neighborhoods = await dataSource.watchNeighborhoods(cityId: 7, limit: 10).first;
      expect(neighborhoods, isEmpty);
      final outboxRows = await database.select(database.outboxTable).get();
      expect(outboxRows.single.entityType, 'neighborhood');
      expect(outboxRows.single.operation, 'delete');
      expect(outboxRows.single.entityId, 1);
    });

    test('a never-synced temp (negative) id is removed locally with no outbox row', () async {
      final rowId = await dataSource.queueNeighborhoodMutation(
        neighborhood: const Neighborhood(id: -7, cityId: 7, name: 'Book club'),
        operation: 'create',
        payloadJson: '{}',
      );

      await dataSource.queueDeletedNeighborhood(-7, payloadJson: '{"cityId":7}');

      final neighborhoods = await dataSource.watchAllNeighborhoods(limit: 10).first;
      expect(neighborhoods.where((n) => n.id == -7), isEmpty);
      final outboxRows = await database.select(database.outboxTable).get();
      expect(outboxRows.where((r) => r.id == rowId), isEmpty);
    });
  });

  test('confirmDeletedNeighborhood hard-removes the tombstoned row and its outbox row', () async {
    await dataSource.saveNeighborhood(const Neighborhood(id: 1, cityId: 7, name: 'Zamalek'));
    await dataSource.queueDeletedNeighborhood(1, payloadJson: '{"cityId":7}');
    final outboxRowId = (await database.select(database.outboxTable).get()).single.id;

    await dataSource.confirmDeletedNeighborhood(1, replayedOutboxRowId: outboxRowId);

    final neighborhoods = await dataSource.watchAllNeighborhoods(limit: 10).first;
    expect(neighborhoods, isEmpty);
    expect(await database.select(database.outboxTable).get(), isEmpty);
  });

  group('applyNeighborhoodsSnapshot', () {
    test('upserts a server row that is not already dirty locally', () async {
      await dataSource.applyNeighborhoodsSnapshot(const [Neighborhood(id: 1, cityId: 7, name: 'From Server')]);

      final row = await (database.select(database.neighborhoodsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.name, 'From Server');
    });

    test('a clean positive-id row absent from the server list is soft-tombstoned', () async {
      await dataSource.saveNeighborhood(const Neighborhood(id: 1, cityId: 7, name: 'Gone Server-Side'));

      await dataSource.applyNeighborhoodsSnapshot(const []);

      final row = await (database.select(database.neighborhoodsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.isDeleted, isTrue);
    });

    test('a dirty row is not overwritten or tombstoned by a snapshot pull', () async {
      await dataSource.queueNeighborhoodMutation(
        neighborhood: const Neighborhood(id: 1, cityId: 7, name: 'Local Edit'),
        operation: 'update',
        payloadJson: '{}',
      );

      await dataSource.applyNeighborhoodsSnapshot(const [Neighborhood(id: 1, cityId: 7, name: 'Stale Server Copy')]);

      final row = await (database.select(database.neighborhoodsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.name, 'Local Edit');
      expect(row.isDeleted, isFalse);
    });

    test('a previously-tombstoned row that reappears in the server list is restored', () async {
      await dataSource.saveNeighborhood(const Neighborhood(id: 1, cityId: 7, name: 'Was Deleted'));
      await dataSource.applyNeighborhoodsSnapshot(const []);

      await dataSource.applyNeighborhoodsSnapshot(const [Neighborhood(id: 1, cityId: 7, name: 'Back Again')]);

      final row = await (database.select(database.neighborhoodsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.isDeleted, isFalse);
      expect(row.name, 'Back Again');
    });
  });

  group('applyNeighborhoodChanges', () {
    test('upserts a clean row given in upserts', () async {
      await dataSource.applyNeighborhoodChanges(
        upserts: const [Neighborhood(id: 1, cityId: 7, name: 'From Server')],
        tombstoneIds: const [],
      );

      final row = await (database.select(database.neighborhoodsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.name, 'From Server');
    });

    test('a dirty row is not overwritten by an upsert for the same id', () async {
      await dataSource.queueNeighborhoodMutation(
        neighborhood: const Neighborhood(id: 1, cityId: 7, name: 'Local Edit'),
        operation: 'update',
        payloadJson: '{}',
      );

      await dataSource.applyNeighborhoodChanges(
        upserts: const [Neighborhood(id: 1, cityId: 7, name: 'From Server')],
        tombstoneIds: const [],
      );

      final row = await (database.select(database.neighborhoodsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.name, 'Local Edit');
      expect(row.isDirty, isTrue);
    });

    test('tombstones exactly the ids given in tombstoneIds — no absence inference', () async {
      await dataSource.saveNeighborhoods(const [
        Neighborhood(id: 1, cityId: 7, name: 'Untouched'),
        Neighborhood(id: 2, cityId: 7, name: 'Removed'),
      ]);

      await dataSource.applyNeighborhoodChanges(upserts: const [], tombstoneIds: const [2]);

      final untouched =
          await (database.select(database.neighborhoodsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(untouched.isDeleted, isFalse);
      final removed =
          await (database.select(database.neighborhoodsTable)..where((t) => t.id.equals(2))).getSingle();
      expect(removed.isDeleted, isTrue);
    });

    test('a dirty row is not tombstoned even if its id is given in tombstoneIds', () async {
      await dataSource.queueNeighborhoodMutation(
        neighborhood: const Neighborhood(id: 1, cityId: 7, name: 'Local Edit'),
        operation: 'update',
        payloadJson: '{}',
      );

      await dataSource.applyNeighborhoodChanges(upserts: const [], tombstoneIds: const [1]);

      final row = await (database.select(database.neighborhoodsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.isDeleted, isFalse);
      expect(row.isDirty, isTrue);
    });
  });

  group('getNeighborhoodsSyncCursor / saveNeighborhoodsSyncCursor', () {
    test('reads 0 when never synced', () async {
      expect(await dataSource.getNeighborhoodsSyncCursor(), 0);
    });

    test('round-trips a saved cursor', () async {
      await dataSource.saveNeighborhoodsSyncCursor(137);

      expect(await dataSource.getNeighborhoodsSyncCursor(), 137);
    });

    test('a later save overwrites the earlier value', () async {
      await dataSource.saveNeighborhoodsSyncCursor(50);
      await dataSource.saveNeighborhoodsSyncCursor(90);

      expect(await dataSource.getNeighborhoodsSyncCursor(), 90);
    });

    test('does not clobber a previously-written lastSyncedAt', () async {
      final syncedAt = DateTime(2026, 9, 15);
      await database.into(database.syncStateTable).insertOnConflictUpdate(
            SyncStateTableCompanion.insert(collection: 'neighborhoods', lastSyncedAt: Value(syncedAt)),
          );

      await dataSource.saveNeighborhoodsSyncCursor(137);

      final row = await (database.select(database.syncStateTable)
            ..where((t) => t.collection.equals('neighborhoods')))
          .getSingle();
      expect(row.cursor, '137');
      expect(row.lastSyncedAt, syncedAt);
    });
  });
}
