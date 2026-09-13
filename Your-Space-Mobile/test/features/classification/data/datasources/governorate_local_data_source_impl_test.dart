import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/governorate.dart';
import 'package:your_space_mobile/features/classification/data/datasources/governorate_local_data_source_impl.dart';

void main() {
  late AppDatabase database;
  late GovernorateLocalDataSourceImpl dataSource;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dataSource = GovernorateLocalDataSourceImpl(database);
  });

  tearDown(() => database.close());

  test('watchGovernorates emits the seeded set and reacts to a later saveGovernorate call', () async {
    await dataSource.saveGovernorates(const [
      Governorate(id: 1, name: 'Cairo', isLocked: true),
      Governorate(id: 2, name: 'Giza', isLocked: true),
    ]);

    final emissions = <List<Governorate>>[];
    final subscription = dataSource.watchGovernorates(limit: 10).listen(emissions.add);
    addTearDown(subscription.cancel);

    await pumpEventQueue();
    expect(emissions, hasLength(1));
    expect(
      emissions.single,
      containsAll(const [
        Governorate(id: 1, name: 'Cairo', isLocked: true),
        Governorate(id: 2, name: 'Giza', isLocked: true),
      ]),
    );

    await dataSource.saveGovernorate(const Governorate(id: 3, name: 'Alexandria', isLocked: true));
    await pumpEventQueue();

    expect(emissions.last, hasLength(3));
  });

  test('saveGovernorate upserts rather than duplicates an existing id', () async {
    await dataSource.saveGovernorate(const Governorate(id: 1, name: 'Cairo', isLocked: true));
    await dataSource.saveGovernorate(const Governorate(id: 1, name: 'Cairo Governorate', isLocked: true));

    final governorates = await dataSource.watchGovernorates(limit: 10).first;

    expect(governorates, const [Governorate(id: 1, name: 'Cairo Governorate', isLocked: true)]);
  });

  test('search matches name and nameAr independently', () async {
    await dataSource.saveGovernorates(const [
      Governorate(id: 1, name: 'Cairo', nameAr: 'القاهرة', isLocked: true),
      Governorate(id: 2, name: 'Giza', isLocked: true),
    ]);

    expect((await dataSource.watchGovernorates(search: 'cairo', limit: 10).first).map((g) => g.id), [1]);
    expect((await dataSource.watchGovernorates(search: 'القاهرة', limit: 10).first).map((g) => g.id), [1]);
    expect((await dataSource.watchGovernorates(search: 'giza', limit: 10).first).map((g) => g.id), [2]);
  });

  test('limit truncates the result set', () async {
    await dataSource.saveGovernorates([
      for (var i = 1; i <= 5; i++) Governorate(id: i, name: 'Governorate $i', isLocked: true),
    ]);

    final governorates = await dataSource.watchGovernorates(limit: 2).first;

    expect(governorates, hasLength(2));
  });

  test('countGovernorates matches the unlimited watchGovernorates length and respects search', () async {
    await dataSource.saveGovernorates(const [
      Governorate(id: 1, name: 'Cairo', isLocked: true),
      Governorate(id: 2, name: 'Giza', isLocked: true),
      Governorate(id: 3, name: 'Aswan Book club', isLocked: true),
    ]);

    expect(await dataSource.countGovernorates(), 3);
    expect(await dataSource.countGovernorates(search: 'club'), 1);
  });

  test('isLocked survives the round trip through drift', () async {
    await dataSource.saveGovernorate(const Governorate(id: 1, name: 'Custom', isLocked: false));

    final governorate = await dataSource.watchGovernorates(limit: 10).first;

    expect(governorate.single.isLocked, isFalse);
  });

  group('applyGovernoratesSnapshot', () {
    test('upserts a server row that is not already dirty locally', () async {
      await dataSource.applyGovernoratesSnapshot(const [Governorate(id: 1, name: 'From Server', isLocked: true)]);

      final row =
          await (database.select(database.governoratesTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.name, 'From Server');
    });

    test('a clean positive-id row absent from the server list is soft-tombstoned', () async {
      await dataSource.saveGovernorate(const Governorate(id: 1, name: 'Gone Server-Side'));

      await dataSource.applyGovernoratesSnapshot(const []);

      final row =
          await (database.select(database.governoratesTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.isDeleted, isTrue);
    });

    test('a previously-tombstoned row that reappears in the server list is restored', () async {
      await dataSource.saveGovernorate(const Governorate(id: 1, name: 'Was Deleted'));
      await dataSource.applyGovernoratesSnapshot(const []);

      await dataSource.applyGovernoratesSnapshot(const [Governorate(id: 1, name: 'Back Again', isLocked: true)]);

      final row =
          await (database.select(database.governoratesTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.isDeleted, isFalse);
      expect(row.name, 'Back Again');
    });
  });
}
