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

  group('queueGroupMutation', () {
    test('writes a dirty group row and one outbox row in the same transaction, returning its id', () async {
      const group = Group(id: -1, name: 'Offline Create');

      final rowId = await dataSource.queueGroupMutation(
        group: group,
        operation: 'create',
        payloadJson: '{"name":"Offline Create"}',
      );

      final row = await (database.select(database.groupsTable)..where((t) => t.id.equals(-1))).getSingle();
      expect(row.isDirty, isTrue);
      expect(row.name, 'Offline Create');

      final outboxRow = await (database.select(database.outboxTable)..where((t) => t.id.equals(rowId))).getSingle();
      expect(outboxRow.entityType, 'group');
      expect(outboxRow.entityId, -1);
      expect(outboxRow.operation, 'create');
      expect(outboxRow.payloadJson, '{"name":"Offline Create"}');
    });
  });

  group('confirmSyncedGroup', () {
    test('clears isDirty on the group row and deletes the replayed outbox row', () async {
      final rowId = await dataSource.queueGroupMutation(
        group: const Group(id: 5, name: 'Dirty'),
        operation: 'update',
        payloadJson: '{"id":5}',
      );

      await dataSource.confirmSyncedGroup(const Group(id: 5, name: 'Confirmed'), replayedOutboxRowId: rowId);

      final row = await (database.select(database.groupsTable)..where((t) => t.id.equals(5))).getSingle();
      expect(row.isDirty, isFalse);
      expect(row.name, 'Confirmed');

      final remainingOutbox = await database.select(database.outboxTable).get();
      expect(remainingOutbox, isEmpty);
    });
  });

  group('reconcileCreatedGroup', () {
    test('inserts under the real id, deletes the temp row, and deletes the replayed outbox row', () async {
      const tempId = -12345;
      final rowId = await dataSource.queueGroupMutation(
        group: const Group(id: tempId, name: 'Offline Group'),
        operation: 'create',
        payloadJson: '{"name":"Offline Group"}',
      );

      const realGroup = Group(id: 999, name: 'Offline Group');
      await dataSource.reconcileCreatedGroup(tempId: tempId, realGroup: realGroup, replayedOutboxRowId: rowId);

      final tempRow =
          await (database.select(database.groupsTable)..where((t) => t.id.equals(tempId))).getSingleOrNull();
      expect(tempRow, isNull);

      final realRow = await (database.select(database.groupsTable)..where((t) => t.id.equals(999))).getSingle();
      expect(realRow.name, 'Offline Group');

      final remainingOutbox = await database.select(database.outboxTable).get();
      expect(remainingOutbox, isEmpty);
    });
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
