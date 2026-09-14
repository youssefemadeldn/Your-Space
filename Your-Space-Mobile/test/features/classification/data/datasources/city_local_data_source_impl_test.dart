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
}
