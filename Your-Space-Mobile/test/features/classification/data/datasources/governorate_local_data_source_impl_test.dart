import 'package:drift/drift.dart' show Value;
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

  group('queueGovernorateMutation', () {
    test('writes a dirty governorate row and one outbox row in the same transaction, returning its id',
        () async {
      const governorate = Governorate(id: -1, name: 'Offline Create');

      final rowId = await dataSource.queueGovernorateMutation(
        governorate: governorate,
        operation: 'create',
        payloadJson: '{"name":"Offline Create"}',
      );

      final row =
          await (database.select(database.governoratesTable)..where((t) => t.id.equals(-1))).getSingle();
      expect(row.isDirty, isTrue);
      expect(row.name, 'Offline Create');

      final outboxRow =
          await (database.select(database.outboxTable)..where((t) => t.id.equals(rowId))).getSingle();
      expect(outboxRow.entityType, 'governorate');
      expect(outboxRow.entityId, -1);
      expect(outboxRow.operation, 'create');
      expect(outboxRow.payloadJson, '{"name":"Offline Create"}');
    });
  });

  group('confirmSyncedGovernorate', () {
    test('clears isDirty on the governorate row and deletes the replayed outbox row', () async {
      final rowId = await dataSource.queueGovernorateMutation(
        governorate: const Governorate(id: 5, name: 'Dirty'),
        operation: 'create',
        payloadJson: '{"id":5}',
      );

      await dataSource.confirmSyncedGovernorate(
        const Governorate(id: 5, name: 'Confirmed'),
        replayedOutboxRowId: rowId,
      );

      final row =
          await (database.select(database.governoratesTable)..where((t) => t.id.equals(5))).getSingle();
      expect(row.isDirty, isFalse);
      expect(row.name, 'Confirmed');

      final remainingOutbox = await database.select(database.outboxTable).get();
      expect(remainingOutbox, isEmpty);
    });
  });

  group('reconcileCreatedGovernorate', () {
    test('inserts under the real id, deletes the temp row, and deletes the replayed outbox row', () async {
      const tempId = -12345;
      final rowId = await dataSource.queueGovernorateMutation(
        governorate: const Governorate(id: tempId, name: 'Offline Governorate'),
        operation: 'create',
        payloadJson: '{"name":"Offline Governorate"}',
      );

      const realGovernorate = Governorate(id: 999, name: 'Offline Governorate');
      await dataSource.reconcileCreatedGovernorate(
        tempId: tempId,
        realGovernorate: realGovernorate,
        replayedOutboxRowId: rowId,
      );

      final tempRow = await (database.select(database.governoratesTable)..where((t) => t.id.equals(tempId)))
          .getSingleOrNull();
      expect(tempRow, isNull);

      final realRow =
          await (database.select(database.governoratesTable)..where((t) => t.id.equals(999))).getSingle();
      expect(realRow.name, 'Offline Governorate');

      final remainingOutbox = await database.select(database.outboxTable).get();
      expect(remainingOutbox, isEmpty);
    });

    test(
      'row 8.9: rewrites a dependent CitiesTable row and a still-queued city outbox payload referencing the '
      'temp governorate id',
      () async {
        const tempId = -777;
        final governorateRowId = await dataSource.queueGovernorateMutation(
          governorate: const Governorate(id: tempId, name: 'Offline Governorate'),
          operation: 'create',
          payloadJson: '{"name":"Offline Governorate"}',
        );
        await database.into(database.citiesTable).insert(
              CitiesTableCompanion.insert(
                id: const Value(-1),
                name: 'Offline City',
                governorateId: tempId,
                isDirty: const Value(true),
              ),
            );
        await database.into(database.outboxTable).insert(
              OutboxTableCompanion.insert(
                entityType: 'city',
                entityId: -1,
                operation: 'create',
                payloadJson: '{"governorateId":$tempId,"name":"Offline City"}',
              ),
            );

        const realGovernorate = Governorate(id: 999, name: 'Offline Governorate');
        await dataSource.reconcileCreatedGovernorate(
          tempId: tempId,
          realGovernorate: realGovernorate,
          replayedOutboxRowId: governorateRowId,
        );

        final cityRow =
            await (database.select(database.citiesTable)..where((t) => t.id.equals(-1))).getSingle();
        expect(cityRow.governorateId, 999);

        final cityOutboxRow = (await (database.select(database.outboxTable)
                  ..where((t) => t.entityType.equals('city')))
                .get())
            .single;
        expect(cityOutboxRow.payloadJson, contains('"governorateId":999'));
      },
    );
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

  group('applyGovernorateChanges', () {
    test('upserts a clean row given in upserts', () async {
      await dataSource.applyGovernorateChanges(
        upserts: const [Governorate(id: 1, name: 'From Server', isLocked: true)],
        tombstoneIds: const [],
      );

      final row =
          await (database.select(database.governoratesTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.name, 'From Server');
    });

    test('a dirty row is not overwritten by an upsert for the same id', () async {
      await dataSource.queueGovernorateMutation(
        governorate: const Governorate(id: 1, name: 'Local Edit'),
        operation: 'create',
        payloadJson: '{"id":1}',
      );

      await dataSource.applyGovernorateChanges(
        upserts: const [Governorate(id: 1, name: 'From Server', isLocked: true)],
        tombstoneIds: const [],
      );

      final row =
          await (database.select(database.governoratesTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.name, 'Local Edit');
      expect(row.isDirty, isTrue);
    });

    test('tombstones exactly the ids given in tombstoneIds — no absence inference', () async {
      await dataSource.saveGovernorates(const [
        Governorate(id: 1, name: 'Untouched', isLocked: true),
        Governorate(id: 2, name: 'Removed', isLocked: true),
      ]);

      await dataSource.applyGovernorateChanges(upserts: const [], tombstoneIds: const [2]);

      final untouched =
          await (database.select(database.governoratesTable)..where((t) => t.id.equals(1))).getSingle();
      expect(untouched.isDeleted, isFalse);
      final removed =
          await (database.select(database.governoratesTable)..where((t) => t.id.equals(2))).getSingle();
      expect(removed.isDeleted, isTrue);
    });

    test('a dirty row is not tombstoned even if its id is given in tombstoneIds', () async {
      await dataSource.queueGovernorateMutation(
        governorate: const Governorate(id: 1, name: 'Local Edit'),
        operation: 'create',
        payloadJson: '{"id":1}',
      );

      await dataSource.applyGovernorateChanges(upserts: const [], tombstoneIds: const [1]);

      final row =
          await (database.select(database.governoratesTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.isDeleted, isFalse);
      expect(row.isDirty, isTrue);
    });
  });

  group('getGovernoratesSyncCursor / saveGovernoratesSyncCursor', () {
    test('reads 0 when never synced', () async {
      expect(await dataSource.getGovernoratesSyncCursor(), 0);
    });

    test('round-trips a saved cursor', () async {
      await dataSource.saveGovernoratesSyncCursor(137);

      expect(await dataSource.getGovernoratesSyncCursor(), 137);
    });

    test('a later save overwrites the earlier value', () async {
      await dataSource.saveGovernoratesSyncCursor(50);
      await dataSource.saveGovernoratesSyncCursor(90);

      expect(await dataSource.getGovernoratesSyncCursor(), 90);
    });

    test('does not clobber a previously-written lastSyncedAt', () async {
      final syncedAt = DateTime(2026, 9, 13);
      await database.into(database.syncStateTable).insertOnConflictUpdate(
            SyncStateTableCompanion.insert(collection: 'governorates', lastSyncedAt: Value(syncedAt)),
          );

      await dataSource.saveGovernoratesSyncCursor(137);

      final row = await (database.select(database.syncStateTable)
            ..where((t) => t.collection.equals('governorates')))
          .getSingle();
      expect(row.cursor, '137');
      expect(row.lastSyncedAt, syncedAt);
    });
  });
}
