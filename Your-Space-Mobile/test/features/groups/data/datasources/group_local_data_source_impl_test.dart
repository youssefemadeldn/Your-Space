import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/features/groups/data/datasources/group_local_data_source_impl.dart';

void main() {
  late AppDatabase database;
  late GroupLocalDataSourceImpl dataSource;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dataSource = GroupLocalDataSourceImpl(database);
  });

  tearDown(() => database.close());

  test('watchGroups emits the seeded set and reacts to a later saveGroup call', () async {
    await dataSource.saveGroups(const [Group(id: 1, name: 'Family'), Group(id: 2, name: 'Friends')]);

    final emissions = <List<Group>>[];
    final subscription = dataSource.watchGroups(limit: 10).listen(emissions.add);
    addTearDown(subscription.cancel);

    await pumpEventQueue();
    expect(emissions, hasLength(1));
    expect(emissions.single, containsAll(const [Group(id: 1, name: 'Family'), Group(id: 2, name: 'Friends')]));

    await dataSource.saveGroup(const Group(id: 3, name: 'Book club'));
    await pumpEventQueue();

    expect(emissions.last, hasLength(3));
  });

  test('saveGroup upserts rather than duplicates an existing id', () async {
    await dataSource.saveGroup(const Group(id: 1, name: 'Family'));
    await dataSource.saveGroup(const Group(id: 1, name: 'The Family'));

    final groups = await dataSource.watchGroups(limit: 10).first;

    expect(groups, const [Group(id: 1, name: 'The Family')]);
  });

  test('search matches name and nameAr independently', () async {
    await dataSource.saveGroups(const [
      Group(id: 1, name: 'Family', nameAr: 'العائلة'),
      Group(id: 2, name: 'Book club'),
    ]);

    expect((await dataSource.watchGroups(search: 'family', limit: 10).first).map((g) => g.id), [1]);
    expect((await dataSource.watchGroups(search: 'العائلة', limit: 10).first).map((g) => g.id), [1]);
    expect((await dataSource.watchGroups(search: 'book', limit: 10).first).map((g) => g.id), [2]);
  });

  test('limit truncates the result set', () async {
    await dataSource.saveGroups([for (var i = 1; i <= 5; i++) Group(id: i, name: 'Group $i')]);

    final groups = await dataSource.watchGroups(limit: 2).first;

    expect(groups, hasLength(2));
  });

  test('countGroups matches the unlimited watchGroups length and respects search', () async {
    await dataSource.saveGroups(const [
      Group(id: 1, name: 'Family'),
      Group(id: 2, name: 'Friends'),
      Group(id: 3, name: 'Book club'),
    ]);

    expect(await dataSource.countGroups(), 3);
    expect(await dataSource.countGroups(search: 'club'), 1);
  });

  group('applyGroupsSnapshot', () {
    test('upserts a server row that is not already dirty locally', () async {
      await dataSource.applyGroupsSnapshot(const [Group(id: 1, name: 'From Server')]);

      final row = await (database.select(database.groupsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.name, 'From Server');
    });

    test('a clean positive-id row absent from the server list is soft-tombstoned', () async {
      await dataSource.saveGroup(const Group(id: 1, name: 'Gone Server-Side'));

      await dataSource.applyGroupsSnapshot(const []);

      final row = await (database.select(database.groupsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.isDeleted, isTrue);
    });

    test('a previously-tombstoned row that reappears in the server list is restored', () async {
      await dataSource.saveGroup(const Group(id: 1, name: 'Was Deleted'));
      await dataSource.applyGroupsSnapshot(const []);

      await dataSource.applyGroupsSnapshot(const [Group(id: 1, name: 'Back Again')]);

      final row = await (database.select(database.groupsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.isDeleted, isFalse);
      expect(row.name, 'Back Again');
    });
  });
}
