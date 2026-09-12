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
    expect(await database.select(database.outboxTable).get(), isEmpty);
    expect(await database.select(database.syncStateTable).get(), isEmpty);
  });

  test('schema is at v2 and OutboxTable.lastAttemptAt is reachable', () async {
    expect(database.schemaVersion, 2);

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
}
