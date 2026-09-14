import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/city.dart';
import 'package:your_space_mobile/features/classification/data/datasources/city_local_data_source_impl.dart';

void main() {
  late AppDatabase database;
  late CityLocalDataSourceImpl dataSource;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dataSource = CityLocalDataSourceImpl(database);
  });

  tearDown(() => database.close());

  test('watchCities emits the seeded set and reacts to a later saveCity call', () async {
    await dataSource.saveCities(const [
      City(id: 1, governorateId: 7, name: 'Maadi'),
      City(id: 2, governorateId: 7, name: 'Nasr City'),
    ]);

    final emissions = <List<City>>[];
    final subscription = dataSource.watchCities(governorateId: 7, limit: 10).listen(emissions.add);
    addTearDown(subscription.cancel);

    await pumpEventQueue();
    expect(emissions, hasLength(1));
    expect(
      emissions.single,
      containsAll(const [City(id: 1, governorateId: 7, name: 'Maadi'), City(id: 2, governorateId: 7, name: 'Nasr City')]),
    );

    await dataSource.saveCity(const City(id: 3, governorateId: 7, name: 'Heliopolis'));
    await pumpEventQueue();

    expect(emissions.last, hasLength(3));
  });

  test('watchCities filters strictly by governorateId', () async {
    await dataSource.saveCities(const [
      City(id: 1, governorateId: 7, name: 'Maadi'),
      City(id: 2, governorateId: 8, name: '6th of October'),
    ]);

    final cities = await dataSource.watchCities(governorateId: 7, limit: 10).first;

    expect(cities.map((c) => c.id), [1]);
  });

  test('watchAllCities is parent-agnostic', () async {
    await dataSource.saveCities(const [
      City(id: 1, governorateId: 7, name: 'Maadi'),
      City(id: 2, governorateId: 8, name: '6th of October'),
    ]);

    final cities = await dataSource.watchAllCities(limit: 10).first;

    expect(cities.map((c) => c.id), containsAll([1, 2]));
  });

  test('saveCity upserts rather than duplicates an existing id', () async {
    await dataSource.saveCity(const City(id: 1, governorateId: 7, name: 'Maadi'));
    await dataSource.saveCity(const City(id: 1, governorateId: 7, name: 'Maadi (Renamed)'));

    final cities = await dataSource.watchCities(governorateId: 7, limit: 10).first;

    expect(cities, const [City(id: 1, governorateId: 7, name: 'Maadi (Renamed)')]);
  });

  test('search matches name and nameAr independently', () async {
    await dataSource.saveCities(const [
      City(id: 1, governorateId: 7, name: 'Maadi', nameAr: 'المعادي'),
      City(id: 2, governorateId: 7, name: 'Nasr City'),
    ]);

    expect((await dataSource.watchCities(governorateId: 7, search: 'maadi', limit: 10).first).map((c) => c.id), [1]);
    expect(
      (await dataSource.watchCities(governorateId: 7, search: 'المعادي', limit: 10).first).map((c) => c.id),
      [1],
    );
    expect((await dataSource.watchCities(governorateId: 7, search: 'nasr', limit: 10).first).map((c) => c.id), [2]);
  });

  test('limit truncates the result set', () async {
    await dataSource.saveCities([for (var i = 1; i <= 5; i++) City(id: i, governorateId: 7, name: 'City $i')]);

    final cities = await dataSource.watchCities(governorateId: 7, limit: 2).first;

    expect(cities, hasLength(2));
  });

  test('countCities matches the unlimited watchCities length and respects search', () async {
    await dataSource.saveCities(const [
      City(id: 1, governorateId: 7, name: 'Maadi'),
      City(id: 2, governorateId: 7, name: 'Nasr City'),
      City(id: 3, governorateId: 7, name: 'Book club'),
    ]);

    expect(await dataSource.countCities(governorateId: 7), 3);
    expect(await dataSource.countCities(governorateId: 7, search: 'club'), 1);
  });

  test('deleteCityLocal hard-removes the row', () async {
    await dataSource.saveCity(const City(id: 1, governorateId: 7, name: 'Maadi'));

    await dataSource.deleteCityLocal(1);

    final cities = await dataSource.watchCities(governorateId: 7, limit: 10).first;
    expect(cities, isEmpty);
  });

  test('queueCityMutation writes a dirty row and appends one outbox row', () async {
    final rowId = await dataSource.queueCityMutation(
      city: const City(id: -1, governorateId: 7, name: 'Book club'),
      operation: 'create',
      payloadJson: '{"governorateId":7,"name":"Book club"}',
    );

    final cities = await dataSource.watchCities(governorateId: 7, limit: 10).first;
    expect(cities.single.name, 'Book club');
    final outboxRows = await database.select(database.outboxTable).get();
    expect(outboxRows.single.id, rowId);
    expect(outboxRows.single.entityType, 'city');
    expect(outboxRows.single.operation, 'create');
  });

  test('confirmSyncedCity overwrites the row and removes the outbox row', () async {
    final rowId = await dataSource.queueCityMutation(
      city: const City(id: 1, governorateId: 7, name: 'Maadi'),
      operation: 'update',
      payloadJson: '{}',
    );

    await dataSource.confirmSyncedCity(
      const City(id: 1, governorateId: 7, name: 'Maadi (Confirmed)'),
      replayedOutboxRowId: rowId,
    );

    final cities = await dataSource.watchCities(governorateId: 7, limit: 10).first;
    expect(cities.single.name, 'Maadi (Confirmed)');
    expect(await database.select(database.outboxTable).get(), isEmpty);
  });

  test('reconcileCreatedCity swaps the temp id for the real one and clears the outbox row', () async {
    final rowId = await dataSource.queueCityMutation(
      city: const City(id: -42, governorateId: 7, name: 'Book club'),
      operation: 'create',
      payloadJson: '{}',
    );

    await dataSource.reconcileCreatedCity(
      tempId: -42,
      realCity: const City(id: 5, governorateId: 7, name: 'Book club'),
      replayedOutboxRowId: rowId,
    );

    final cities = await dataSource.watchCities(governorateId: 7, limit: 10).first;
    expect(cities.map((c) => c.id), [5]);
    expect(await database.select(database.outboxTable).get(), isEmpty);
  });

  group('queueDeletedCity', () {
    test('a real (positive) id is soft-tombstoned and queued for the outbox', () async {
      await dataSource.saveCity(const City(id: 1, governorateId: 7, name: 'Maadi'));

      await dataSource.queueDeletedCity(1, payloadJson: '{"governorateId":7}');

      final cities = await dataSource.watchCities(governorateId: 7, limit: 10).first;
      expect(cities, isEmpty);
      final outboxRows = await database.select(database.outboxTable).get();
      expect(outboxRows.single.entityType, 'city');
      expect(outboxRows.single.operation, 'delete');
      expect(outboxRows.single.entityId, 1);
    });

    test('a never-synced temp (negative) id is removed locally with no outbox row', () async {
      final rowId = await dataSource.queueCityMutation(
        city: const City(id: -7, governorateId: 7, name: 'Book club'),
        operation: 'create',
        payloadJson: '{}',
      );

      await dataSource.queueDeletedCity(-7, payloadJson: '{"governorateId":7}');

      final cities = await dataSource.watchAllCities(limit: 10).first;
      expect(cities.where((c) => c.id == -7), isEmpty);
      final outboxRows = await database.select(database.outboxTable).get();
      expect(outboxRows.where((r) => r.id == rowId), isEmpty);
    });
  });

  test('confirmDeletedCity hard-removes the tombstoned row and its outbox row', () async {
    await dataSource.saveCity(const City(id: 1, governorateId: 7, name: 'Maadi'));
    await dataSource.queueDeletedCity(1, payloadJson: '{"governorateId":7}');
    final outboxRowId = (await database.select(database.outboxTable).get()).single.id;

    await dataSource.confirmDeletedCity(1, replayedOutboxRowId: outboxRowId);

    expect(await database.select(database.citiesTable).get(), isEmpty);
    expect(await database.select(database.outboxTable).get(), isEmpty);
  });

  group('applyCitiesSnapshot', () {
    test('upserts a server row that is not already dirty locally', () async {
      await dataSource.applyCitiesSnapshot(const [City(id: 1, governorateId: 7, name: 'From Server')]);

      final row = await (database.select(database.citiesTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.name, 'From Server');
    });

    test('a clean positive-id row absent from the server list is soft-tombstoned', () async {
      await dataSource.saveCity(const City(id: 1, governorateId: 7, name: 'Gone Server-Side'));

      await dataSource.applyCitiesSnapshot(const []);

      final row = await (database.select(database.citiesTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.isDeleted, isTrue);
    });

    test('a dirty row is not overwritten or tombstoned by a snapshot pull', () async {
      await dataSource.queueCityMutation(
        city: const City(id: 1, governorateId: 7, name: 'Local Edit'),
        operation: 'update',
        payloadJson: '{}',
      );

      await dataSource.applyCitiesSnapshot(const [City(id: 1, governorateId: 7, name: 'Stale Server Copy')]);

      final row = await (database.select(database.citiesTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.name, 'Local Edit');
      expect(row.isDeleted, isFalse);
    });

    test('a previously-tombstoned row that reappears in the server list is restored', () async {
      await dataSource.saveCity(const City(id: 1, governorateId: 7, name: 'Was Deleted'));
      await dataSource.applyCitiesSnapshot(const []);

      await dataSource.applyCitiesSnapshot(const [City(id: 1, governorateId: 7, name: 'Back Again')]);

      final row = await (database.select(database.citiesTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.isDeleted, isFalse);
      expect(row.name, 'Back Again');
    });
  });
}
