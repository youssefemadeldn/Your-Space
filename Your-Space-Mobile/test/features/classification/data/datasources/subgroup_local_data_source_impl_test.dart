import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/subgroup.dart';
import 'package:your_space_mobile/features/classification/data/datasources/subgroup_local_data_source_impl.dart';

void main() {
  late AppDatabase database;
  late SubGroupLocalDataSourceImpl dataSource;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dataSource = SubGroupLocalDataSourceImpl(database);
  });

  tearDown(() => database.close());

  test('watchSubGroups emits the seeded set and reacts to a later saveSubGroup call', () async {
    await dataSource.saveSubGroups(const [
      SubGroup(id: 1, groupId: 7, name: 'Immediate Family'),
      SubGroup(id: 2, groupId: 7, name: 'Extended Family'),
    ]);

    final emissions = <List<SubGroup>>[];
    final subscription = dataSource.watchSubGroups(groupId: 7, limit: 10).listen(emissions.add);
    addTearDown(subscription.cancel);

    await pumpEventQueue();
    expect(emissions, hasLength(1));
    expect(
      emissions.single,
      containsAll(const [
        SubGroup(id: 1, groupId: 7, name: 'Immediate Family'),
        SubGroup(id: 2, groupId: 7, name: 'Extended Family'),
      ]),
    );

    await dataSource.saveSubGroup(const SubGroup(id: 3, groupId: 7, name: 'Cousins'));
    await pumpEventQueue();

    expect(emissions.last, hasLength(3));
  });

  test('watchSubGroups filters strictly by groupId', () async {
    await dataSource.saveSubGroups(const [
      SubGroup(id: 1, groupId: 7, name: 'Immediate Family'),
      SubGroup(id: 2, groupId: 8, name: 'University Friends'),
    ]);

    final subGroups = await dataSource.watchSubGroups(groupId: 7, limit: 10).first;

    expect(subGroups.map((s) => s.id), [1]);
  });

  test('watchAllSubGroups is parent-agnostic', () async {
    await dataSource.saveSubGroups(const [
      SubGroup(id: 1, groupId: 7, name: 'Immediate Family'),
      SubGroup(id: 2, groupId: 8, name: 'University Friends'),
    ]);

    final subGroups = await dataSource.watchAllSubGroups(limit: 10).first;

    expect(subGroups.map((s) => s.id), containsAll([1, 2]));
  });

  test('saveSubGroup upserts rather than duplicates an existing id', () async {
    await dataSource.saveSubGroup(const SubGroup(id: 1, groupId: 7, name: 'Immediate Family'));
    await dataSource.saveSubGroup(const SubGroup(id: 1, groupId: 7, name: 'Immediate Family (Renamed)'));

    final subGroups = await dataSource.watchSubGroups(groupId: 7, limit: 10).first;

    expect(subGroups, const [SubGroup(id: 1, groupId: 7, name: 'Immediate Family (Renamed)')]);
  });

  test('search matches name and nameAr independently', () async {
    await dataSource.saveSubGroups(const [
      SubGroup(id: 1, groupId: 7, name: 'Immediate Family', nameAr: 'العائلة المباشرة'),
      SubGroup(id: 2, groupId: 7, name: 'University Friends'),
    ]);

    expect(
      (await dataSource.watchSubGroups(groupId: 7, search: 'immediate', limit: 10).first).map((s) => s.id),
      [1],
    );
    expect(
      (await dataSource.watchSubGroups(groupId: 7, search: 'العائلة المباشرة', limit: 10).first).map((s) => s.id),
      [1],
    );
    expect(
      (await dataSource.watchSubGroups(groupId: 7, search: 'university', limit: 10).first).map((s) => s.id),
      [2],
    );
  });

  test('limit truncates the result set', () async {
    await dataSource.saveSubGroups([for (var i = 1; i <= 5; i++) SubGroup(id: i, groupId: 7, name: 'SubGroup $i')]);

    final subGroups = await dataSource.watchSubGroups(groupId: 7, limit: 2).first;

    expect(subGroups, hasLength(2));
  });

  test('countSubGroups matches the unlimited watchSubGroups length and respects search', () async {
    await dataSource.saveSubGroups(const [
      SubGroup(id: 1, groupId: 7, name: 'Immediate Family'),
      SubGroup(id: 2, groupId: 7, name: 'University Friends'),
      SubGroup(id: 3, groupId: 7, name: 'Book club'),
    ]);

    expect(await dataSource.countSubGroups(groupId: 7), 3);
    expect(await dataSource.countSubGroups(groupId: 7, search: 'club'), 1);
  });

  test('deleteSubGroupLocal hard-removes the row', () async {
    await dataSource.saveSubGroup(const SubGroup(id: 1, groupId: 7, name: 'Immediate Family'));

    await dataSource.deleteSubGroupLocal(1);

    final subGroups = await dataSource.watchSubGroups(groupId: 7, limit: 10).first;
    expect(subGroups, isEmpty);
  });

  test('queueSubGroupMutation writes a dirty row and appends one outbox row', () async {
    final rowId = await dataSource.queueSubGroupMutation(
      subGroup: const SubGroup(id: -1, groupId: 7, name: 'Book club'),
      operation: 'create',
      payloadJson: '{"groupId":7,"name":"Book club"}',
    );

    final subGroups = await dataSource.watchSubGroups(groupId: 7, limit: 10).first;
    expect(subGroups.single.name, 'Book club');
    final outboxRows = await database.select(database.outboxTable).get();
    expect(outboxRows.single.id, rowId);
    expect(outboxRows.single.entityType, 'subgroup');
    expect(outboxRows.single.operation, 'create');
  });

  test('confirmSyncedSubGroup overwrites the row and removes the outbox row', () async {
    final rowId = await dataSource.queueSubGroupMutation(
      subGroup: const SubGroup(id: 1, groupId: 7, name: 'Immediate Family'),
      operation: 'update',
      payloadJson: '{}',
    );

    await dataSource.confirmSyncedSubGroup(
      const SubGroup(id: 1, groupId: 7, name: 'Immediate Family (Confirmed)'),
      replayedOutboxRowId: rowId,
    );

    final subGroups = await dataSource.watchSubGroups(groupId: 7, limit: 10).first;
    expect(subGroups.single.name, 'Immediate Family (Confirmed)');
    expect(await database.select(database.outboxTable).get(), isEmpty);
  });

  test('reconcileCreatedSubGroup swaps the temp id for the real one and clears the outbox row', () async {
    final rowId = await dataSource.queueSubGroupMutation(
      subGroup: const SubGroup(id: -42, groupId: 7, name: 'Book club'),
      operation: 'create',
      payloadJson: '{}',
    );

    await dataSource.reconcileCreatedSubGroup(
      tempId: -42,
      realSubGroup: const SubGroup(id: 5, groupId: 7, name: 'Book club'),
      replayedOutboxRowId: rowId,
    );

    final subGroups = await dataSource.watchSubGroups(groupId: 7, limit: 10).first;
    expect(subGroups.map((s) => s.id), [5]);
    expect(await database.select(database.outboxTable).get(), isEmpty);
  });

  group('queueDeletedSubGroup', () {
    test('a real (positive) id is soft-tombstoned and queued for the outbox', () async {
      await dataSource.saveSubGroup(const SubGroup(id: 1, groupId: 7, name: 'Immediate Family'));

      await dataSource.queueDeletedSubGroup(1, payloadJson: '{"groupId":7}');

      final subGroups = await dataSource.watchSubGroups(groupId: 7, limit: 10).first;
      expect(subGroups, isEmpty);
      final outboxRows = await database.select(database.outboxTable).get();
      expect(outboxRows.single.entityType, 'subgroup');
      expect(outboxRows.single.operation, 'delete');
      expect(outboxRows.single.entityId, 1);
    });

    test('a never-synced temp (negative) id is removed locally with no outbox row', () async {
      final rowId = await dataSource.queueSubGroupMutation(
        subGroup: const SubGroup(id: -7, groupId: 7, name: 'Book club'),
        operation: 'create',
        payloadJson: '{}',
      );

      await dataSource.queueDeletedSubGroup(-7, payloadJson: '{"groupId":7}');

      final subGroups = await dataSource.watchAllSubGroups(limit: 10).first;
      expect(subGroups.where((s) => s.id == -7), isEmpty);
      final outboxRows = await database.select(database.outboxTable).get();
      expect(outboxRows.where((r) => r.id == rowId), isEmpty);
    });
  });

  test('confirmDeletedSubGroup hard-removes the tombstoned row and its outbox row', () async {
    await dataSource.saveSubGroup(const SubGroup(id: 1, groupId: 7, name: 'Immediate Family'));
    await dataSource.queueDeletedSubGroup(1, payloadJson: '{"groupId":7}');
    final outboxRowId = (await database.select(database.outboxTable).get()).single.id;

    await dataSource.confirmDeletedSubGroup(1, replayedOutboxRowId: outboxRowId);

    expect(await database.select(database.subGroupsTable).get(), isEmpty);
    expect(await database.select(database.outboxTable).get(), isEmpty);
  });

  group('applySubGroupsSnapshot', () {
    test('upserts a server row that is not already dirty locally', () async {
      await dataSource.applySubGroupsSnapshot(const [SubGroup(id: 1, groupId: 7, name: 'From Server')]);

      final row = await (database.select(database.subGroupsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.name, 'From Server');
    });

    test('a clean positive-id row absent from the server list is soft-tombstoned', () async {
      await dataSource.saveSubGroup(const SubGroup(id: 1, groupId: 7, name: 'Gone Server-Side'));

      await dataSource.applySubGroupsSnapshot(const []);

      final row = await (database.select(database.subGroupsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.isDeleted, isTrue);
    });

    test('a dirty row is not overwritten or tombstoned by a snapshot pull', () async {
      await dataSource.queueSubGroupMutation(
        subGroup: const SubGroup(id: 1, groupId: 7, name: 'Local Edit'),
        operation: 'update',
        payloadJson: '{}',
      );

      await dataSource.applySubGroupsSnapshot(const [SubGroup(id: 1, groupId: 7, name: 'Stale Server Copy')]);

      final row = await (database.select(database.subGroupsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.name, 'Local Edit');
      expect(row.isDeleted, isFalse);
    });

    test('a previously-tombstoned row that reappears in the server list is restored', () async {
      await dataSource.saveSubGroup(const SubGroup(id: 1, groupId: 7, name: 'Was Deleted'));
      await dataSource.applySubGroupsSnapshot(const []);

      await dataSource.applySubGroupsSnapshot(const [SubGroup(id: 1, groupId: 7, name: 'Back Again')]);

      final row = await (database.select(database.subGroupsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.isDeleted, isFalse);
      expect(row.name, 'Back Again');
    });
  });
}
