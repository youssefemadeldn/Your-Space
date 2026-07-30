import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/invite_method.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import 'package:your_space_mobile/features/events/data/datasources/event_guest_remote_data_source_impl.dart';
import 'package:your_space_mobile/features/events/data/models/add_persons_to_event_request.dart';
import 'package:your_space_mobile/features/events/data/models/event_guest_response.dart';
import 'package:your_space_mobile/features/events/data/models/mark_guest_invited_request.dart';
import 'package:your_space_mobile/features/events/data/repositories/event_guest_repository_impl.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest_status.dart';

class MockEventGuestRemoteDataSourceImpl extends Mock implements EventGuestRemoteDataSourceImpl {}

void main() {
  late MockEventGuestRemoteDataSourceImpl remote;
  late EventGuestRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const AddPersonsToEventRequest(personIds: []));
    registerFallbackValue(const MarkGuestInvitedRequest(inviteMethod: InviteMethod.whatsApp));
  });

  setUp(() {
    remote = MockEventGuestRemoteDataSourceImpl();
    repository = EventGuestRepositoryImpl(remote);
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

  test('markInvited passes the wire-formatted invite method and injects eventId', () async {
    when(() => remote.markInvited(1, 5, any())).thenAnswer(
      (_) async => const Right(EventGuestResponse(
        id: 5,
        personId: 10,
        personName: 'Sara Adel',
        groupId: 1,
        groupName: 'Family',
        status: EventGuestStatus.invited,
        inviteMethod: InviteMethod.whatsApp,
      )),
    );

    final result = await repository.markInvited(1, 5, inviteMethod: InviteMethod.whatsApp);

    expect(
      result,
      const Right(EventGuest(
        id: 5,
        eventId: 1,
        personId: 10,
        personName: 'Sara Adel',
        groupId: 1,
        groupName: 'Family',
        status: EventGuestStatus.invited,
        inviteMethod: InviteMethod.whatsApp,
      )),
    );
  });

  test('removeGuest propagates a failure unchanged', () async {
    const failure = ServerFailure(statusCode: 404, message: 'Not found', errorCode: 'EventGuest.NotFound');
    when(() => remote.removeGuest(1, 5)).thenAnswer((_) async => const Left(failure));

    final result = await repository.removeGuest(1, 5);

    expect(result, const Left(failure));
  });
}
