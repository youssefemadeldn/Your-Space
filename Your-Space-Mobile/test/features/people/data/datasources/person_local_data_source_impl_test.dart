import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/features/people/data/datasources/person_local_data_source_impl.dart';

Person _person({
  required int id,
  String name = 'Person',
  String? phoneNumber,
  String? phoneNumber2,
  int groupId = 1,
  int? subGroupId,
  int governorateId = 1,
  int? cityId,
  int? neighborhoodId,
}) =>
    Person(
      id: id,
      name: name,
      phoneNumber: phoneNumber,
      phoneNumber2: phoneNumber2,
      gender: Gender.male,
      groupId: groupId,
      groupName: 'Group $groupId',
      subGroupId: subGroupId,
      subGroupName: subGroupId == null ? null : 'SubGroup $subGroupId',
      governorateId: governorateId,
      governorateName: 'Governorate $governorateId',
      cityId: cityId,
      cityName: cityId == null ? null : 'City $cityId',
      neighborhoodId: neighborhoodId,
      neighborhoodName: neighborhoodId == null ? null : 'Neighborhood $neighborhoodId',
    );

void main() {
  late AppDatabase database;
  late PersonLocalDataSourceImpl dataSource;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dataSource = PersonLocalDataSourceImpl(database);
  });

  tearDown(() => database.close());

  test('watchPersons emits the seeded set and reacts to a later savePerson call', () async {
    await dataSource.savePersons([_person(id: 1, name: 'Alice'), _person(id: 2, name: 'Bob')]);

    final emissions = <List<Person>>[];
    final subscription = dataSource.watchPersons(limit: 10).listen(emissions.add);
    addTearDown(subscription.cancel);

    // Let the initial query flush before mutating — drift schedules its
    // watch notifications asynchronously, so a write issued too close to
    // subscribing can coalesce with the first emission instead of producing
    // a distinct second one.
    await pumpEventQueue();
    expect(emissions, hasLength(1));
    expect(emissions.single, containsAll([_person(id: 1, name: 'Alice'), _person(id: 2, name: 'Bob')]));

    await dataSource.savePerson(_person(id: 3, name: 'Cara'));
    await pumpEventQueue();

    expect(emissions.last, hasLength(3));
    expect(
      emissions.last,
      containsAll([_person(id: 1, name: 'Alice'), _person(id: 2, name: 'Bob'), _person(id: 3, name: 'Cara')]),
    );
  });

  test('savePerson/savePersons upsert rather than duplicate an existing id', () async {
    await dataSource.savePerson(_person(id: 1, name: 'Alice'));
    await dataSource.savePerson(_person(id: 1, name: 'Alice Updated'));

    final people = await dataSource.watchPersons(limit: 10).first;

    expect(people, [_person(id: 1, name: 'Alice Updated')]);
  });

  test('each of the 5 filter dimensions filters correctly, alone and combined', () async {
    await dataSource.savePersons([
      _person(id: 1, groupId: 1, subGroupId: 10, governorateId: 100, cityId: 1000, neighborhoodId: 10000),
      _person(id: 2, groupId: 2, subGroupId: 20, governorateId: 100, cityId: 1000, neighborhoodId: 10000),
      _person(id: 3, groupId: 1, subGroupId: 11, governorateId: 200, cityId: 2000, neighborhoodId: 20000),
    ]);

    expect((await dataSource.watchPersons(groupId: 1, limit: 10).first).map((p) => p.id), [1, 3]);
    expect((await dataSource.watchPersons(subGroupId: 20, limit: 10).first).map((p) => p.id), [2]);
    expect((await dataSource.watchPersons(governorateId: 200, limit: 10).first).map((p) => p.id), [3]);
    expect((await dataSource.watchPersons(cityId: 1000, limit: 10).first).map((p) => p.id), [1, 2]);
    expect((await dataSource.watchPersons(neighborhoodId: 20000, limit: 10).first).map((p) => p.id), [3]);
    expect(
      (await dataSource.watchPersons(groupId: 1, governorateId: 100, limit: 10).first).map((p) => p.id),
      [1],
    );
  });

  test('search matches name, phoneNumber, and phoneNumber2 independently', () async {
    await dataSource.savePersons([
      _person(id: 1, name: 'Nadia Kamal'),
      _person(id: 2, name: 'Other', phoneNumber: '0100000001'),
      _person(id: 3, name: 'Other2', phoneNumber2: '0100000002'),
    ]);

    expect((await dataSource.watchPersons(search: 'nadia', limit: 10).first).map((p) => p.id), [1]);
    expect((await dataSource.watchPersons(search: '0100000001', limit: 10).first).map((p) => p.id), [2]);
    expect((await dataSource.watchPersons(search: '0100000002', limit: 10).first).map((p) => p.id), [3]);
  });

  test('limit truncates the result set', () async {
    await dataSource.savePersons([for (var i = 1; i <= 5; i++) _person(id: i, name: 'Person $i')]);

    final people = await dataSource.watchPersons(limit: 2).first;

    expect(people, hasLength(2));
  });

  test('countPersons matches the unlimited watchPersons length and respects filters', () async {
    await dataSource.savePersons([
      _person(id: 1, groupId: 1),
      _person(id: 2, groupId: 1),
      _person(id: 3, groupId: 2),
    ]);

    expect(await dataSource.countPersons(), 3);
    expect(await dataSource.countPersons(groupId: 1), 2);
  });

  group('queuePersonMutation', () {
    test('writes a dirty person row and one outbox row in the same transaction, returning its id', () async {
      final person = _person(id: -1, name: 'Offline Create');

      final rowId = await dataSource.queuePersonMutation(
        person: person,
        operation: 'create',
        payloadJson: '{"name":"Offline Create"}',
      );

      final row = await (database.select(database.personsTable)..where((t) => t.id.equals(-1))).getSingle();
      expect(row.isDirty, isTrue);
      expect(row.name, 'Offline Create');

      final outboxRow =
          await (database.select(database.outboxTable)..where((t) => t.id.equals(rowId))).getSingle();
      expect(outboxRow.entityType, 'person');
      expect(outboxRow.entityId, -1);
      expect(outboxRow.operation, 'create');
      expect(outboxRow.payloadJson, '{"name":"Offline Create"}');
      expect(outboxRow.retryCount, 0);
      expect(outboxRow.lastAttemptAt, isNull);
    });
  });

  group('confirmSyncedPerson', () {
    test('clears isDirty on the person row and deletes the replayed outbox row', () async {
      final rowId = await dataSource.queuePersonMutation(
        person: _person(id: 5, name: 'Dirty'),
        operation: 'update',
        payloadJson: '{"id":5}',
      );

      await dataSource.confirmSyncedPerson(_person(id: 5, name: 'Confirmed'), replayedOutboxRowId: rowId);

      final row = await (database.select(database.personsTable)..where((t) => t.id.equals(5))).getSingle();
      expect(row.isDirty, isFalse);
      expect(row.name, 'Confirmed');

      final remainingOutbox = await database.select(database.outboxTable).get();
      expect(remainingOutbox, isEmpty);
    });
  });

  group('applyPersonsSnapshot', () {
    test('upserts a server row that is not already dirty locally', () async {
      await dataSource.applyPersonsSnapshot([_person(id: 1, name: 'From Server')]);

      final row = await (database.select(database.personsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.name, 'From Server');
    });

    test('a dirty row is neither overwritten nor tombstoned, even when absent from the server list', () async {
      await dataSource.queuePersonMutation(
        person: _person(id: 1, name: 'Local Edit'),
        operation: 'update',
        payloadJson: '{"id":1}',
      );

      await dataSource.applyPersonsSnapshot([]);

      final row = await (database.select(database.personsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.name, 'Local Edit');
      expect(row.isDirty, isTrue);
      expect(row.isDeleted, isFalse);
    });

    test('a clean positive-id row absent from the server list is soft-tombstoned', () async {
      await dataSource.savePerson(_person(id: 1, name: 'Gone Server-Side'));

      await dataSource.applyPersonsSnapshot([]);

      final row = await (database.select(database.personsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.isDeleted, isTrue);
    });

    test('a temp (negative) id row is never touched regardless of the server list', () async {
      await dataSource.queuePersonMutation(
        person: _person(id: -1, name: 'Offline Create'),
        operation: 'create',
        payloadJson: '{}',
      );

      await dataSource.applyPersonsSnapshot([]);

      final row = await (database.select(database.personsTable)..where((t) => t.id.equals(-1))).getSingle();
      expect(row.isDeleted, isFalse);
      expect(row.name, 'Offline Create');
    });

    test('a previously-tombstoned row that reappears in the server list is restored', () async {
      await dataSource.savePerson(_person(id: 1, name: 'Was Deleted'));
      await dataSource.applyPersonsSnapshot([]);

      await dataSource.applyPersonsSnapshot([_person(id: 1, name: 'Back Again')]);

      final row = await (database.select(database.personsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.isDeleted, isFalse);
      expect(row.name, 'Back Again');
    });
  });

  group('applyPersonChanges', () {
    test('upserts a clean row given in upserts', () async {
      await dataSource.applyPersonChanges(upserts: [_person(id: 1, name: 'From Server')], tombstoneIds: const []);

      final row = await (database.select(database.personsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.name, 'From Server');
    });

    test('a dirty row is not overwritten by an upsert for the same id', () async {
      await dataSource.queuePersonMutation(
        person: _person(id: 1, name: 'Local Edit'),
        operation: 'update',
        payloadJson: '{"id":1}',
      );

      await dataSource.applyPersonChanges(upserts: [_person(id: 1, name: 'From Server')], tombstoneIds: const []);

      final row = await (database.select(database.personsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.name, 'Local Edit');
      expect(row.isDirty, isTrue);
    });

    test('tombstones exactly the ids given in tombstoneIds — no absence inference', () async {
      await dataSource.savePersons([_person(id: 1, name: 'Untouched'), _person(id: 2, name: 'Removed')]);

      await dataSource.applyPersonChanges(upserts: const [], tombstoneIds: const [2]);

      final untouched = await (database.select(database.personsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(untouched.isDeleted, isFalse);
      final removed = await (database.select(database.personsTable)..where((t) => t.id.equals(2))).getSingle();
      expect(removed.isDeleted, isTrue);
    });

    test('a dirty row is not tombstoned even if its id is given in tombstoneIds', () async {
      await dataSource.queuePersonMutation(
        person: _person(id: 1, name: 'Local Edit'),
        operation: 'update',
        payloadJson: '{"id":1}',
      );

      await dataSource.applyPersonChanges(upserts: const [], tombstoneIds: const [1]);

      final row = await (database.select(database.personsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.isDeleted, isFalse);
      expect(row.isDirty, isTrue);
    });
  });

  group('getPersonsSyncCursor / savePersonsSyncCursor', () {
    test('reads 0 when never synced', () async {
      expect(await dataSource.getPersonsSyncCursor(), 0);
    });

    test('round-trips a saved cursor', () async {
      await dataSource.savePersonsSyncCursor(137);

      expect(await dataSource.getPersonsSyncCursor(), 137);
    });

    test('a later save overwrites the earlier value', () async {
      await dataSource.savePersonsSyncCursor(50);
      await dataSource.savePersonsSyncCursor(90);

      expect(await dataSource.getPersonsSyncCursor(), 90);
    });

    test('does not clobber a previously-written lastSyncedAt', () async {
      final syncedAt = DateTime(2026, 9, 13);
      await database.into(database.syncStateTable).insertOnConflictUpdate(
            SyncStateTableCompanion.insert(collection: 'persons', lastSyncedAt: Value(syncedAt)),
          );

      await dataSource.savePersonsSyncCursor(137);

      final row =
          await (database.select(database.syncStateTable)..where((t) => t.collection.equals('persons')))
              .getSingle();
      expect(row.cursor, '137');
      expect(row.lastSyncedAt, syncedAt);
    });
  });

  group('reconcileCreatedPerson', () {
    test(
        'inserts under the real id, deletes the temp row, deletes the replayed outbox row, and patches a pending '
        'update row still referencing the temp id (both entityId and its embedded payload id)', () async {
      const tempId = -12345;
      final createRowId = await dataSource.queuePersonMutation(
        person: _person(id: tempId, name: 'Offline Person'),
        operation: 'create',
        payloadJson: '{"name":"Offline Person"}',
      );
      // Simulates an offline edit of the same not-yet-synced person before
      // the create has synced — a second outbox row keyed to the same
      // temp id (design doc §5's self-referential reconciliation case).
      final updateRowId = await dataSource.queuePersonMutation(
        person: _person(id: tempId, name: 'Offline Person Edited'),
        operation: 'update',
        payloadJson: '{"id":$tempId,"name":"Offline Person Edited"}',
      );

      const realPerson = Person(
        id: 999,
        name: 'Offline Person Edited',
        gender: Gender.male,
        groupId: 1,
        groupName: 'Group 1',
        governorateId: 1,
        governorateName: 'Governorate 1',
      );
      await dataSource.reconcileCreatedPerson(
        tempId: tempId,
        realPerson: realPerson,
        replayedOutboxRowId: createRowId,
      );

      final tempRow =
          await (database.select(database.personsTable)..where((t) => t.id.equals(tempId))).getSingleOrNull();
      expect(tempRow, isNull);

      final realRow =
          await (database.select(database.personsTable)..where((t) => t.id.equals(999))).getSingle();
      expect(realRow.name, 'Offline Person Edited');

      final replayedOutboxRow = await (database.select(database.outboxTable)
            ..where((t) => t.id.equals(createRowId)))
          .getSingleOrNull();
      expect(replayedOutboxRow, isNull);

      final patchedRow =
          await (database.select(database.outboxTable)..where((t) => t.id.equals(updateRowId))).getSingle();
      expect(patchedRow.entityId, 999);
      final patchedPayload = jsonDecode(patchedRow.payloadJson) as Map<String, dynamic>;
      expect(patchedPayload['id'], 999);
      expect(patchedPayload['name'], 'Offline Person Edited');
    });

    test(
      'row 9.9: rewrites a dependent EventGuestsTable row and a still-queued eventGuest outbox payload '
      'referencing the temp person id',
      () async {
        const tempId = -888;
        final personRowId = await dataSource.queuePersonMutation(
          person: _person(id: tempId, name: 'Offline Person'),
          operation: 'create',
          payloadJson: '{"name":"Offline Person"}',
        );
        await database.into(database.eventGuestsTable).insert(
              EventGuestsTableCompanion.insert(
                id: const Value(-1),
                eventId: 7,
                personId: tempId,
                personName: 'Offline Person',
                groupId: 1,
                groupName: 'Group 1',
                status: 'NotInvited',
                isDirty: const Value(true),
              ),
            );
        await database.into(database.outboxTable).insert(
              OutboxTableCompanion.insert(
                entityType: 'eventGuest',
                entityId: -1,
                operation: 'create',
                payloadJson: '{"eventId":7,"personId":$tempId}',
              ),
            );

        const realPerson = Person(
          id: 999,
          name: 'Offline Person',
          gender: Gender.male,
          groupId: 1,
          groupName: 'Group 1',
          governorateId: 1,
          governorateName: 'Governorate 1',
        );
        await dataSource.reconcileCreatedPerson(
          tempId: tempId,
          realPerson: realPerson,
          replayedOutboxRowId: personRowId,
        );

        final guestRow =
            await (database.select(database.eventGuestsTable)..where((t) => t.id.equals(-1))).getSingle();
        expect(guestRow.personId, 999);

        final guestOutboxRow = (await (database.select(database.outboxTable)
                  ..where((t) => t.entityType.equals('eventGuest')))
                .get())
            .single;
        expect(guestOutboxRow.payloadJson, contains('"personId":999'));
      },
    );
  });
}
