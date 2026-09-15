import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/invite_method.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import 'package:your_space_mobile/features/events/data/datasources/base_event_guest_data_source.dart';
import 'package:your_space_mobile/features/events/data/datasources/event_guest_local_data_source_impl.dart';
import 'package:your_space_mobile/features/events/data/models/event_guest_response.dart';
import 'package:your_space_mobile/features/events/data/models/mark_guest_invited_request.dart';
import 'package:your_space_mobile/features/events/data/repositories/event_guest_repository_impl.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest_status.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';

class MockBaseEventGuestDataSource extends Mock implements BaseEventGuestDataSource {}

class MockEventGuestLocalDataSourceImpl extends Mock implements EventGuestLocalDataSourceImpl {}

class MockPersonRepository extends Mock implements PersonRepository {}

const _sara = Person(id: 10, name: 'Sara Adel', gender: Gender.female, groupId: 1, groupName: 'Family', governorateId: 1, governorateName: 'Cairo');
const _omar = Person(id: 11, name: 'Omar Khaled', gender: Gender.male, groupId: 1, groupName: 'Family', governorateId: 1, governorateName: 'Cairo');

void main() {
  late MockBaseEventGuestDataSource remote;
  late MockEventGuestLocalDataSourceImpl local;
  late MockPersonRepository personRepository;
  late EventGuestRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const EventGuest(id: 0, eventId: 0, personId: 0, personName: '', groupId: 0, groupName: ''));
    registerFallbackValue(const MarkGuestInvitedRequest(inviteMethod: InviteMethod.whatsApp));
  });

  setUp(() {
    remote = MockBaseEventGuestDataSource();
    local = MockEventGuestLocalDataSourceImpl();
    personRepository = MockPersonRepository();
    repository = EventGuestRepositoryImpl(remote, local, personRepository);
    when(
      () => local.queueEventGuestMutation(
        guest: any(named: 'guest'),
        operation: any(named: 'operation'),
        payloadJson: any(named: 'payloadJson'),
      ),
    ).thenAnswer((_) async => 99);
    when(() => local.queueDeletedEventGuest(any(), payloadJson: any(named: 'payloadJson')))
        .thenAnswer((_) async {});
    when(() => local.applyEventGuestsSnapshot(any())).thenAnswer((_) async {});
  });

  test('getEventGuests injects the route eventId into each mapped entity', () async {
    when(() => remote.getEventGuests(1, pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResponse(
        items: [
          EventGuestResponse(
            id: 5,
            personId: 10,
            personName: 'Sara Adel',
            groupId: 1,
            groupName: 'Family',
            status: EventGuestStatus.notInvited,
          ),
        ],
        pageIndex: 1,
        totalPages: 1,
        totalItems: 1,
      )),
    );

    final result = await repository.getEventGuests(1, pageIndex: 1, pageSize: 20);

    expect(result.isRight(), isTrue);
    final page = result.getOrElse(() => throw StateError('expected Right'));
    expect(page.items.single.eventId, 1);
    expect(page.items.single.personName, 'Sara Adel');
  });

  test('watchEventGuests delegates straight to the local data source', () {
    when(() => local.watchEventGuests(eventId: 1, groupId: null, status: null, limit: 20)).thenAnswer(
      (_) => Stream.value(const [
        EventGuest(id: 5, eventId: 1, personId: 10, personName: 'Sara Adel', groupId: 1, groupName: 'Family'),
      ]),
    );

    final stream = repository.watchEventGuests(eventId: 1, limit: 20);

    expect(
      stream,
      emits(const [
        EventGuest(id: 5, eventId: 1, personId: 10, personName: 'Sara Adel', groupId: 1, groupName: 'Family'),
      ]),
    );
  });

  group('addPersonsToEvent (bulk-add expansion, pure optimistic path)', () {
    test('resolves the given ids against the local Person cache and queues one create per new guest', () async {
      when(() => personRepository.watchPersons(limit: any(named: 'limit')))
          .thenAnswer((_) => Stream.value(const [_sara, _omar]));
      when(() => local.watchEventGuests(eventId: 1, limit: any(named: 'limit')))
          .thenAnswer((_) => Stream.value(const []));

      final result = await repository.addPersonsToEvent(eventId: 1, personIds: [10, 11]);

      expect(result.isRight(), isTrue);
      final bulk = result.getOrElse(() => throw StateError('expected Right'));
      expect(bulk.requestedCount, 2);
      expect(bulk.addedCount, 2);
      expect(bulk.alreadyPresentCount, 0);
      verify(
        () => local.queueEventGuestMutation(
          guest: any(named: 'guest'),
          operation: 'create',
          payloadJson: any(named: 'payloadJson'),
        ),
      ).called(2);
    });

    test('already-present persons are excluded and reported, not re-queued', () async {
      when(() => personRepository.watchPersons(limit: any(named: 'limit')))
          .thenAnswer((_) => Stream.value(const [_sara, _omar]));
      when(() => local.watchEventGuests(eventId: 1, limit: any(named: 'limit'))).thenAnswer(
        (_) => Stream.value(const [
          EventGuest(id: 1, eventId: 1, personId: 10, personName: 'Sara Adel', groupId: 1, groupName: 'Family'),
        ]),
      );

      final result = await repository.addPersonsToEvent(eventId: 1, personIds: [10, 11]);

      final bulk = result.getOrElse(() => throw StateError('expected Right'));
      expect(bulk.addedCount, 1);
      expect(bulk.alreadyPresentCount, 1);
      verify(
        () => local.queueEventGuestMutation(
          guest: any(named: 'guest'),
          operation: 'create',
          payloadJson: any(named: 'payloadJson'),
        ),
      ).called(1);
    });
  });

  group('addGroupToEvent (bulk-add expansion)', () {
    test('resolves every person in the group from the local cache', () async {
      when(() => personRepository.watchPersons(groupId: 1, limit: any(named: 'limit')))
          .thenAnswer((_) => Stream.value(const [_sara, _omar]));
      when(() => local.watchEventGuests(eventId: 1, limit: any(named: 'limit')))
          .thenAnswer((_) => Stream.value(const []));

      final result = await repository.addGroupToEvent(eventId: 1, groupId: 1);

      final bulk = result.getOrElse(() => throw StateError('expected Right'));
      expect(bulk.addedCount, 2);
    });
  });

  group('markInvited (pure optimistic path)', () {
    test('queues an update via the outbox and returns immediately', () async {
      when(() => local.watchEventGuests(eventId: 1, limit: any(named: 'limit'))).thenAnswer(
        (_) => Stream.value(const [
          EventGuest(id: 5, eventId: 1, personId: 10, personName: 'Sara Adel', groupId: 1, groupName: 'Family'),
        ]),
      );

      final result = await repository.markInvited(1, 5, inviteMethod: InviteMethod.whatsApp);

      expect(result.isRight(), isTrue);
      final guest = result.getOrElse(() => throw StateError('expected Right'));
      expect(guest.status, EventGuestStatus.invited);
      expect(guest.inviteMethod, InviteMethod.whatsApp);
      verify(
        () => local.queueEventGuestMutation(
          guest: any(named: 'guest'),
          operation: 'update',
          payloadJson: any(named: 'payloadJson'),
        ),
      ).called(1);
      verifyNever(() => remote.markInvited(any(), any(), any()));
    });
  });

  group('removeGuest (pure optimistic path)', () {
    test('queues a delete via the outbox and returns immediately with no remote call', () async {
      final result = await repository.removeGuest(1, 5);

      expect(result, const Right(unit));
      verify(() => local.queueDeletedEventGuest(5, payloadJson: any(named: 'payloadJson'))).called(1);
      verifyNever(() => remote.removeGuest(any(), any()));
    });
  });

  group('refreshEventGuests (permanent full-refetch-as-delta)', () {
    test('applies the fetched snapshot', () async {
      when(() => remote.getAllMineEventGuests()).thenAnswer(
        (_) async => const Right([
          EventGuestResponse(
            id: 1,
            eventId: 7,
            personId: 10,
            personName: 'Sara Adel',
            groupId: 1,
            groupName: 'Family',
            status: EventGuestStatus.notInvited,
          ),
        ]),
      );

      final result = await repository.refreshEventGuests();

      expect(result, const Right(unit));
      final captured = verify(() => local.applyEventGuestsSnapshot(captureAny())).captured;
      expect((captured.single as List<EventGuest>).map((g) => g.id), [1]);
    });

    test('propagates a failure unchanged', () async {
      const failure = NetworkFailure();
      when(() => remote.getAllMineEventGuests()).thenAnswer((_) async => const Left(failure));

      final result = await repository.refreshEventGuests();

      expect(result, const Left(failure));
      verifyNever(() => local.applyEventGuestsSnapshot(any()));
    });
  });
}
