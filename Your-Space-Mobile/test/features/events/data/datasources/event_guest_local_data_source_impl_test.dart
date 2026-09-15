import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/features/events/data/datasources/event_guest_local_data_source_impl.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest_status.dart';

void main() {
  late AppDatabase database;
  late EventGuestLocalDataSourceImpl dataSource;

  const guest1 = EventGuest(id: 1, eventId: 7, personId: 1, personName: 'Sara', groupId: 1, groupName: 'Family');
  const guest2 = EventGuest(id: 2, eventId: 7, personId: 2, personName: 'Omar', groupId: 2, groupName: 'Friends');

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dataSource = EventGuestLocalDataSourceImpl(database);
  });

  tearDown(() => database.close());

  test('watchEventGuests emits the seeded set scoped to eventId', () async {
    await dataSource.saveEventGuests(const [
      guest1,
      guest2,
      EventGuest(id: 3, eventId: 8, personId: 3, personName: 'Ali', groupId: 1, groupName: 'Family'),
    ]);

    final guests = await dataSource.watchEventGuests(eventId: 7, limit: 10).first;

    expect(guests.map((g) => g.id), containsAll([1, 2]));
  });

  test('watchEventGuests filters by groupId and status', () async {
    await dataSource.saveEventGuests(const [
      guest1,
      EventGuest(
        id: 2,
        eventId: 7,
        personId: 2,
        personName: 'Omar',
        groupId: 2,
        groupName: 'Friends',
        status: EventGuestStatus.invited,
      ),
    ]);

    expect((await dataSource.watchEventGuests(eventId: 7, groupId: 2, limit: 10).first).map((g) => g.id), [2]);
    expect(
      (await dataSource.watchEventGuests(eventId: 7, status: EventGuestStatus.invited, limit: 10).first)
          .map((g) => g.id),
      [2],
    );
  });

  test('countEventGuests matches the unlimited watch length and respects filters', () async {
    await dataSource.saveEventGuests(const [guest1, guest2]);

    expect(await dataSource.countEventGuests(eventId: 7), 2);
    expect(await dataSource.countEventGuests(eventId: 7, groupId: 1), 1);
  });

  test('deleteEventGuestLocal hard-removes the row', () async {
    await dataSource.saveEventGuests(const [guest1]);

    await dataSource.deleteEventGuestLocal(1);

    expect(await dataSource.watchEventGuests(eventId: 7, limit: 10).first, isEmpty);
  });

  test('queueEventGuestMutation writes a dirty row and appends one outbox row', () async {
    final rowId = await dataSource.queueEventGuestMutation(
      guest: const EventGuest(id: -1, eventId: 7, personId: 1, personName: 'Sara', groupId: 1, groupName: 'Family'),
      operation: 'create',
      payloadJson: '{"eventId":7,"personId":1}',
    );

    final guests = await dataSource.watchEventGuests(eventId: 7, limit: 10).first;
    expect(guests.single.personName, 'Sara');
    final outboxRows = await database.select(database.outboxTable).get();
    expect(outboxRows.single.id, rowId);
    expect(outboxRows.single.entityType, 'eventGuest');
  });

  test('confirmSyncedEventGuest overwrites the row and removes the outbox row', () async {
    final rowId = await dataSource.queueEventGuestMutation(
      guest: guest1.copyWithStatus(EventGuestStatus.invited),
      operation: 'update',
      payloadJson: '{}',
    );

    await dataSource.confirmSyncedEventGuest(
      guest1.copyWithStatus(EventGuestStatus.invited),
      replayedOutboxRowId: rowId,
    );

    final guests = await dataSource.watchEventGuests(eventId: 7, limit: 10).first;
    expect(guests.single.status, EventGuestStatus.invited);
    expect(await database.select(database.outboxTable).get(), isEmpty);
  });

  test('reconcileCreatedEventGuest swaps the temp id for the real one and clears the outbox row', () async {
    final rowId = await dataSource.queueEventGuestMutation(
      guest: const EventGuest(id: -42, eventId: 7, personId: 1, personName: 'Sara', groupId: 1, groupName: 'Family'),
      operation: 'create',
      payloadJson: '{}',
    );

    await dataSource.reconcileCreatedEventGuest(
      tempId: -42,
      realGuest: guest1,
      replayedOutboxRowId: rowId,
    );

    final guests = await dataSource.watchEventGuests(eventId: 7, limit: 10).first;
    expect(guests.map((g) => g.id), [1]);
    expect(await database.select(database.outboxTable).get(), isEmpty);
  });

  group('queueDeletedEventGuest', () {
    test('a real (positive) id is soft-tombstoned and queued for the outbox', () async {
      await dataSource.saveEventGuests(const [guest1]);

      await dataSource.queueDeletedEventGuest(1, payloadJson: '{"eventId":7}');

      expect(await dataSource.watchEventGuests(eventId: 7, limit: 10).first, isEmpty);
      final outboxRows = await database.select(database.outboxTable).get();
      expect(outboxRows.single.operation, 'delete');
    });

    test('a never-synced temp (negative) id is removed locally with no outbox row', () async {
      final rowId = await dataSource.queueEventGuestMutation(
        guest: const EventGuest(id: -7, eventId: 7, personId: 1, personName: 'Sara', groupId: 1, groupName: 'Family'),
        operation: 'create',
        payloadJson: '{}',
      );

      await dataSource.queueDeletedEventGuest(-7, payloadJson: '{"eventId":7}');

      expect(await dataSource.watchAllEventGuests(limit: 10).first, isEmpty);
      final outboxRows = await database.select(database.outboxTable).get();
      expect(outboxRows.where((r) => r.id == rowId), isEmpty);
    });
  });

  test('confirmDeletedEventGuest hard-removes the tombstoned row and its outbox row', () async {
    await dataSource.saveEventGuests(const [guest1]);
    await dataSource.queueDeletedEventGuest(1, payloadJson: '{"eventId":7}');
    final outboxRowId = (await database.select(database.outboxTable).get()).single.id;

    await dataSource.confirmDeletedEventGuest(1, replayedOutboxRowId: outboxRowId);

    expect(await database.select(database.eventGuestsTable).get(), isEmpty);
    expect(await database.select(database.outboxTable).get(), isEmpty);
  });

  group('applyEventGuestsSnapshot (permanent full-refetch-as-delta)', () {
    test('upserts a server row that is not already dirty locally', () async {
      await dataSource.applyEventGuestsSnapshot(const [guest1]);

      final guests = await dataSource.watchEventGuests(eventId: 7, limit: 10).first;
      expect(guests.single.personName, 'Sara');
    });

    test('a clean positive-id row absent from the server list is soft-tombstoned', () async {
      await dataSource.saveEventGuests(const [guest1]);

      await dataSource.applyEventGuestsSnapshot(const []);

      expect(await dataSource.watchEventGuests(eventId: 7, limit: 10).first, isEmpty);
    });

    test('a dirty row is not overwritten or tombstoned by a snapshot pull', () async {
      await dataSource.queueEventGuestMutation(
        guest: guest1.copyWithStatus(EventGuestStatus.invited),
        operation: 'update',
        payloadJson: '{}',
      );

      await dataSource.applyEventGuestsSnapshot(const [guest1]);

      final guests = await dataSource.watchEventGuests(eventId: 7, limit: 10).first;
      expect(guests.single.status, EventGuestStatus.invited);
    });
  });
}

extension on EventGuest {
  EventGuest copyWithStatus(EventGuestStatus status) => EventGuest(
        id: id,
        eventId: eventId,
        personId: personId,
        personName: personName,
        personPhoneNumber: personPhoneNumber,
        groupId: groupId,
        groupName: groupName,
        status: status,
        inviteMethod: inviteMethod,
        invitedAt: invitedAt,
      );
}
