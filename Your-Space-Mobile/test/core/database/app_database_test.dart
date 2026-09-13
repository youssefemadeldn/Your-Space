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
    expect(await database.select(database.outboxTable).get(), isEmpty);
    expect(await database.select(database.syncStateTable).get(), isEmpty);
  });

  test('OutboxTable.lastAttemptAt is reachable', () async {
    expect(database.schemaVersion, 3);

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
    expect(database.schemaVersion, 3);

    final id = await database.into(database.groupsTable).insert(
          GroupsTableCompanion.insert(id: const Value(1), name: 'Family'),
        );
    final row = await (database.select(database.groupsTable)..where((t) => t.id.equals(id))).getSingle();
    expect(row.name, 'Family');
    expect(row.isDeleted, isFalse);
    expect(row.isDirty, isFalse);
  });
}
