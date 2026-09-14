import 'package:drift/drift.dart' show Value;
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

    test(
      'row 8.15: rewrites a dependent SubGroupsTable row and a still-queued subgroup outbox payload '
      'referencing the temp group id',
      () async {
        const tempId = -777;
        final groupRowId = await dataSource.queueGroupMutation(
          group: const Group(id: tempId, name: 'Offline Group'),
          operation: 'create',
          payloadJson: '{"name":"Offline Group"}',
        );
        await database.into(database.subGroupsTable).insert(
              SubGroupsTableCompanion.insert(
                id: const Value(-1),
                name: 'Offline SubGroup',
                groupId: tempId,
                isDirty: const Value(true),
              ),
            );
        await database.into(database.outboxTable).insert(
              OutboxTableCompanion.insert(
                entityType: 'subgroup',
                entityId: -1,
                operation: 'create',
                payloadJson: '{"groupId":$tempId,"name":"Offline SubGroup"}',
              ),
            );

        const realGroup = Group(id: 999, name: 'Offline Group');
        await dataSource.reconcileCreatedGroup(tempId: tempId, realGroup: realGroup, replayedOutboxRowId: groupRowId);

        final subGroupRow =
            await (database.select(database.subGroupsTable)..where((t) => t.id.equals(-1))).getSingle();
        expect(subGroupRow.groupId, 999);

        final subGroupOutboxRow = (await (database.select(database.outboxTable)
                  ..where((t) => t.entityType.equals('subgroup')))
                .get())
            .single;
        expect(subGroupOutboxRow.payloadJson, contains('"groupId":999'));
      },
    );
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

  group('applyGroupChanges', () {
    test('upserts a clean row given in upserts', () async {
      await dataSource.applyGroupChanges(upserts: const [Group(id: 1, name: 'From Server')], tombstoneIds: const []);

      final row = await (database.select(database.groupsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.name, 'From Server');
    });

    test('a dirty row is not overwritten by an upsert for the same id', () async {
      await dataSource.queueGroupMutation(
        group: const Group(id: 1, name: 'Local Edit'),
        operation: 'update',
        payloadJson: '{"id":1}',
      );

      await dataSource.applyGroupChanges(upserts: const [Group(id: 1, name: 'From Server')], tombstoneIds: const []);

      final row = await (database.select(database.groupsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.name, 'Local Edit');
      expect(row.isDirty, isTrue);
    });

    test('tombstones exactly the ids given in tombstoneIds — no absence inference', () async {
      await dataSource.saveGroups(const [Group(id: 1, name: 'Untouched'), Group(id: 2, name: 'Removed')]);

      await dataSource.applyGroupChanges(upserts: const [], tombstoneIds: const [2]);

      final untouched = await (database.select(database.groupsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(untouched.isDeleted, isFalse);
      final removed = await (database.select(database.groupsTable)..where((t) => t.id.equals(2))).getSingle();
      expect(removed.isDeleted, isTrue);
    });

    test('a dirty row is not tombstoned even if its id is given in tombstoneIds', () async {
      await dataSource.queueGroupMutation(
        group: const Group(id: 1, name: 'Local Edit'),
        operation: 'update',
        payloadJson: '{"id":1}',
      );

      await dataSource.applyGroupChanges(upserts: const [], tombstoneIds: const [1]);

      final row = await (database.select(database.groupsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.isDeleted, isFalse);
      expect(row.isDirty, isTrue);
    });
  });

  group('getGroupsSyncCursor / saveGroupsSyncCursor', () {
    test('reads 0 when never synced', () async {
      expect(await dataSource.getGroupsSyncCursor(), 0);
    });

    test('round-trips a saved cursor', () async {
      await dataSource.saveGroupsSyncCursor(137);

      expect(await dataSource.getGroupsSyncCursor(), 137);
    });

    test('a later save overwrites the earlier value', () async {
      await dataSource.saveGroupsSyncCursor(50);
      await dataSource.saveGroupsSyncCursor(90);

      expect(await dataSource.getGroupsSyncCursor(), 90);
    });

    test('does not clobber a previously-written lastSyncedAt', () async {
      final syncedAt = DateTime(2026, 9, 13);
      await database.into(database.syncStateTable).insertOnConflictUpdate(
            SyncStateTableCompanion.insert(collection: 'groups', lastSyncedAt: Value(syncedAt)),
          );

      await dataSource.saveGroupsSyncCursor(137);

      final row =
          await (database.select(database.syncStateTable)..where((t) => t.collection.equals('groups')))
              .getSingle();
      expect(row.cursor, '137');
      expect(row.lastSyncedAt, syncedAt);
    });
  });
}
