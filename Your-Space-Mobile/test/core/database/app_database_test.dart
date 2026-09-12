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
}
