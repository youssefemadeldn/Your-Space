import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/features/events/data/datasources/event_local_data_source_impl.dart';
import 'package:your_space_mobile/features/events/domain/entities/event.dart';

void main() {
  late AppDatabase database;
  late EventLocalDataSourceImpl dataSource;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dataSource = EventLocalDataSourceImpl(database);
  });

  tearDown(() => database.close());

  test('watchEvents emits the seeded set and reacts to a later saveEvent call', () async {
    await dataSource.saveEvents(const [
      Event(id: 1, name: "Sara's Birthday"),
      Event(id: 2, name: 'New Year Gathering'),
    ]);

    final emissions = <List<Event>>[];
    final subscription = dataSource.watchEvents(limit: 10).listen(emissions.add);
    addTearDown(subscription.cancel);

    await pumpEventQueue();
    expect(emissions, hasLength(1));
    expect(emissions.single, hasLength(2));

    await dataSource.saveEvent(const Event(id: 3, name: 'Housewarming'));
    await pumpEventQueue();

    expect(emissions.last, hasLength(3));
  });

  test('saveEvent upserts rather than duplicates an existing id', () async {
    await dataSource.saveEvent(const Event(id: 1, name: "Sara's Birthday"));
    await dataSource.saveEvent(const Event(id: 1, name: "Sara's Birthday (Renamed)"));

    final events = await dataSource.watchEvents(limit: 10).first;

    expect(events, const [Event(id: 1, name: "Sara's Birthday (Renamed)")]);
  });

  test('search matches name and nameAr independently', () async {
    await dataSource.saveEvents(const [
      Event(id: 1, name: "Sara's Birthday", nameAr: 'عيد ميلاد سارة'),
      Event(id: 2, name: 'New Year Gathering'),
    ]);

    expect((await dataSource.watchEvents(search: 'sara', limit: 10).first).map((e) => e.id), [1]);
    expect((await dataSource.watchEvents(search: 'عيد ميلاد سارة', limit: 10).first).map((e) => e.id), [1]);
    expect((await dataSource.watchEvents(search: 'new year', limit: 10).first).map((e) => e.id), [2]);
  });

  test('limit truncates the result set', () async {
    await dataSource.saveEvents([for (var i = 1; i <= 5; i++) Event(id: i, name: 'Event $i')]);

    final events = await dataSource.watchEvents(limit: 2).first;

    expect(events, hasLength(2));
  });

  test('countEvents matches the unlimited watchEvents length and respects search', () async {
    await dataSource.saveEvents(const [
      Event(id: 1, name: "Sara's Birthday"),
      Event(id: 2, name: 'New Year Gathering'),
      Event(id: 3, name: 'Book club'),
    ]);

    expect(await dataSource.countEvents(), 3);
    expect(await dataSource.countEvents(search: 'club'), 1);
  });

  test('deleteEventLocal hard-removes the row', () async {
    await dataSource.saveEvent(const Event(id: 1, name: "Sara's Birthday"));

    await dataSource.deleteEventLocal(1);

    final events = await dataSource.watchEvents(limit: 10).first;
    expect(events, isEmpty);
  });

  test('queueEventMutation writes a dirty row and appends one outbox row', () async {
    final rowId = await dataSource.queueEventMutation(
      event: const Event(id: -1, name: 'Book club'),
      operation: 'create',
      payloadJson: '{"name":"Book club"}',
    );

    final events = await dataSource.watchEvents(limit: 10).first;
    expect(events.single.name, 'Book club');
    final outboxRows = await database.select(database.outboxTable).get();
    expect(outboxRows.single.id, rowId);
    expect(outboxRows.single.entityType, 'event');
    expect(outboxRows.single.operation, 'create');
  });

  test('confirmSyncedEvent overwrites the row and removes the outbox row', () async {
    final rowId = await dataSource.queueEventMutation(
      event: const Event(id: 1, name: "Sara's Birthday"),
      operation: 'update',
      payloadJson: '{}',
    );

    await dataSource.confirmSyncedEvent(
      const Event(id: 1, name: "Sara's Birthday (Confirmed)"),
      replayedOutboxRowId: rowId,
    );

    final events = await dataSource.watchEvents(limit: 10).first;
    expect(events.single.name, "Sara's Birthday (Confirmed)");
    expect(await database.select(database.outboxTable).get(), isEmpty);
  });

  test('reconcileCreatedEvent swaps the temp id for the real one and clears the outbox row', () async {
    final rowId = await dataSource.queueEventMutation(
      event: const Event(id: -42, name: 'Book club'),
      operation: 'create',
      payloadJson: '{}',
    );

    await dataSource.reconcileCreatedEvent(
      tempId: -42,
      realEvent: const Event(id: 5, name: 'Book club'),
      replayedOutboxRowId: rowId,
    );

    final events = await dataSource.watchEvents(limit: 10).first;
    expect(events.map((e) => e.id), [5]);
    expect(await database.select(database.outboxTable).get(), isEmpty);
  });

  group('applyEventsSnapshot', () {
    test('upserts a server row that is not already dirty locally', () async {
      await dataSource.applyEventsSnapshot(const [Event(id: 1, name: 'From Server')]);

      final row = await (database.select(database.eventsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.name, 'From Server');
    });

    test('a clean positive-id row absent from the server list is soft-tombstoned', () async {
      await dataSource.saveEvent(const Event(id: 1, name: 'Gone Server-Side'));

      await dataSource.applyEventsSnapshot(const []);

      final row = await (database.select(database.eventsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.isDeleted, isTrue);
    });

    test('a dirty row is not overwritten or tombstoned by a snapshot pull', () async {
      await dataSource.queueEventMutation(
        event: const Event(id: 1, name: 'Local Edit'),
        operation: 'update',
        payloadJson: '{}',
      );

      await dataSource.applyEventsSnapshot(const [Event(id: 1, name: 'Stale Server Copy')]);

      final row = await (database.select(database.eventsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.name, 'Local Edit');
      expect(row.isDeleted, isFalse);
    });

    test('a previously-tombstoned row that reappears in the server list is restored', () async {
      await dataSource.saveEvent(const Event(id: 1, name: 'Was Deleted'));
      await dataSource.applyEventsSnapshot(const []);

      await dataSource.applyEventsSnapshot(const [Event(id: 1, name: 'Back Again')]);

      final row = await (database.select(database.eventsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.isDeleted, isFalse);
      expect(row.name, 'Back Again');
    });
  });

  group('applyEventChanges', () {
    test('upserts a clean row given in upserts', () async {
      await dataSource.applyEventChanges(
        upserts: const [Event(id: 1, name: 'From Server')],
        tombstoneIds: const [],
      );

      final row = await (database.select(database.eventsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.name, 'From Server');
    });

    test('a dirty row is not overwritten by an upsert for the same id', () async {
      await dataSource.queueEventMutation(
        event: const Event(id: 1, name: 'Local Edit'),
        operation: 'update',
        payloadJson: '{}',
      );

      await dataSource.applyEventChanges(
        upserts: const [Event(id: 1, name: 'From Server')],
        tombstoneIds: const [],
      );

      final row = await (database.select(database.eventsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.name, 'Local Edit');
      expect(row.isDirty, isTrue);
    });

    test('tombstones exactly the ids given in tombstoneIds — no absence inference', () async {
      await dataSource.saveEvents(const [
        Event(id: 1, name: 'Untouched'),
        Event(id: 2, name: 'Removed'),
      ]);

      await dataSource.applyEventChanges(upserts: const [], tombstoneIds: const [2]);

      final untouched = await (database.select(database.eventsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(untouched.isDeleted, isFalse);
      final removed = await (database.select(database.eventsTable)..where((t) => t.id.equals(2))).getSingle();
      expect(removed.isDeleted, isTrue);
    });

    test('a dirty row is not tombstoned even if its id is given in tombstoneIds', () async {
      await dataSource.queueEventMutation(
        event: const Event(id: 1, name: 'Local Edit'),
        operation: 'update',
        payloadJson: '{}',
      );

      await dataSource.applyEventChanges(upserts: const [], tombstoneIds: const [1]);

      final row = await (database.select(database.eventsTable)..where((t) => t.id.equals(1))).getSingle();
      expect(row.isDeleted, isFalse);
      expect(row.isDirty, isTrue);
    });
  });

  group('getEventsSyncCursor / saveEventsSyncCursor', () {
    test('reads 0 when never synced', () async {
      expect(await dataSource.getEventsSyncCursor(), 0);
    });

    test('round-trips a saved cursor', () async {
      await dataSource.saveEventsSyncCursor(137);

      expect(await dataSource.getEventsSyncCursor(), 137);
    });

    test('a later save overwrites the earlier value', () async {
      await dataSource.saveEventsSyncCursor(50);
      await dataSource.saveEventsSyncCursor(90);

      expect(await dataSource.getEventsSyncCursor(), 90);
    });
  });
}
