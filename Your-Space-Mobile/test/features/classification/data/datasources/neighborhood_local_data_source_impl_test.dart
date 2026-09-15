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
}
