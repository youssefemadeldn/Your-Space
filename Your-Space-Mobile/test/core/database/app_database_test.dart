import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('schema creates cleanly and every table starts empty', () async {
    expect(await database.select(database.personsTable).get(), isEmpty);
    expect(await database.select(database.groupsTable).get(), isEmpty);
    expect(await database.select(database.governoratesTable).get(), isEmpty);
    expect(await database.select(database.citiesTable).get(), isEmpty);
    expect(await database.select(database.subGroupsTable).get(), isEmpty);
    expect(await database.select(database.neighborhoodsTable).get(), isEmpty);
    expect(await database.select(database.outboxTable).get(), isEmpty);
    expect(await database.select(database.syncStateTable).get(), isEmpty);
  });

  test('OutboxTable.lastAttemptAt is reachable', () async {
    expect(database.schemaVersion, 7);

    final id = await database.into(database.outboxTable).insert(
          OutboxTableCompanion.insert(
            entityType: 'person',
            entityId: 1,
            operation: 'create',
            payloadJson: '{}',
            lastAttemptAt: Value(DateTime(2026, 1, 1)),
          ),
        );
    final row = await (database.select(database.outboxTable)..where((t) => t.id.equals(id))).getSingle();
    expect(row.lastAttemptAt, DateTime(2026, 1, 1));
  });

  test('schema is at v3 and GroupsTable is reachable', () async {
    expect(database.schemaVersion, 7);

    final id = await database.into(database.groupsTable).insert(
          GroupsTableCompanion.insert(id: const Value(1), name: 'Family'),
        );
    final row = await (database.select(database.groupsTable)..where((t) => t.id.equals(id))).getSingle();
    expect(row.name, 'Family');
    expect(row.isDeleted, isFalse);
    expect(row.isDirty, isFalse);
  });

  test('schema is at v4 and GovernoratesTable is reachable', () async {
    expect(database.schemaVersion, 7);

    final id = await database.into(database.governoratesTable).insert(
          GovernoratesTableCompanion.insert(id: const Value(1), name: 'Cairo', isLocked: const Value(true)),
        );
    final row =
        await (database.select(database.governoratesTable)..where((t) => t.id.equals(id))).getSingle();
    expect(row.name, 'Cairo');
    expect(row.isLocked, isTrue);
    expect(row.isDeleted, isFalse);
    expect(row.isDirty, isFalse);
  });

  test('schema is at v5 and CitiesTable is reachable', () async {
    expect(database.schemaVersion, 7);

    final id = await database.into(database.citiesTable).insert(
          CitiesTableCompanion.insert(id: const Value(1), name: 'Nasr City', governorateId: 1),
        );
    final row = await (database.select(database.citiesTable)..where((t) => t.id.equals(id))).getSingle();
    expect(row.name, 'Nasr City');
    expect(row.governorateId, 1);
    expect(row.isDeleted, isFalse);
    expect(row.isDirty, isFalse);
  });

  test('schema is at v6 and SubGroupsTable is reachable', () async {
    expect(database.schemaVersion, 7);

    final id = await database.into(database.subGroupsTable).insert(
          SubGroupsTableCompanion.insert(id: const Value(1), name: 'University Friends', groupId: 1),
        );
    final row = await (database.select(database.subGroupsTable)..where((t) => t.id.equals(id))).getSingle();
    expect(row.name, 'University Friends');
    expect(row.groupId, 1);
    expect(row.isDeleted, isFalse);
    expect(row.isDirty, isFalse);
  });

  test('schema is at v7 and NeighborhoodsTable is reachable', () async {
    expect(database.schemaVersion, 7);

    final id = await database.into(database.neighborhoodsTable).insert(
          NeighborhoodsTableCompanion.insert(id: const Value(1), name: 'Zamalek', cityId: 1),
        );
    final row =
        await (database.select(database.neighborhoodsTable)..where((t) => t.id.equals(id))).getSingle();
    expect(row.name, 'Zamalek');
    expect(row.cityId, 1);
    expect(row.isDeleted, isFalse);
    expect(row.isDirty, isFalse);
  });
}
