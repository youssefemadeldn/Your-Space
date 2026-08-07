import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/invite_method.dart';
import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest_status.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_guest_repository.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/event_guest_action_cubit/event_guest_action_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/event_guest_action_cubit/event_guest_action_state.dart';

class MockEventGuestRepository extends Mock implements EventGuestRepository {}

class MockDataRefreshBus extends Mock implements DataRefreshBus {}

void main() {
  late MockEventGuestRepository repository;
  late MockDataRefreshBus dataRefreshBus;
  late EventGuestActionCubit cubit;

  setUpAll(() {
    registerFallbackValue(DataScope.people);
  });

  setUp(() {
    repository = MockEventGuestRepository();
    dataRefreshBus = MockDataRefreshBus();
    cubit = EventGuestActionCubit(repository, dataRefreshBus);
  });

  tearDown(() => cubit.close());

  test('markInvited emits [Submitting, Success]', () async {
    when(() => repository.markInvited(1, 2, inviteMethod: InviteMethod.whatsApp)).thenAnswer(
      (_) async => const Right(EventGuest(
        id: 2,
        eventId: 1,
        personId: 2,
        personName: 'Omar Khaled',
        groupId: 1,
        groupName: 'Family',
        status: EventGuestStatus.invited,
        inviteMethod: InviteMethod.whatsApp,
      )),
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const EventGuestActionSubmitting(), const EventGuestActionSuccess()]),
    );

    unawaited(cubit.markInvited(1, 2, inviteMethod: InviteMethod.whatsApp));
    await expectation;
    verify(() => dataRefreshBus.notify(DataScope.eventGuests)).called(1);
  });

  test('revert emits [Submitting, Success]', () async {
    when(() => repository.revertGuest(1, 2)).thenAnswer(
      (_) async => const Right(EventGuest(
        id: 2,
        eventId: 1,
        personId: 2,
        personName: 'Omar Khaled',
        groupId: 1,
        groupName: 'Family',
        status: EventGuestStatus.notInvited,
      )),
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const EventGuestActionSubmitting(), const EventGuestActionSuccess()]),
    );

    unawaited(cubit.revert(1, 2));
    await expectation;
    verify(() => dataRefreshBus.notify(DataScope.eventGuests)).called(1);
  });

  test('remove emits [Submitting, Success]', () async {
    when(() => repository.removeGuest(1, 2)).thenAnswer((_) async => const Right(unit));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const EventGuestActionSubmitting(), const EventGuestActionSuccess()]),
    );

    unawaited(cubit.remove(1, 2));
    await expectation;
    verify(() => dataRefreshBus.notify(DataScope.eventGuests)).called(1);
  });

  test('markSkipped emits [Submitting, Error] on failure', () async {
    when(() => repository.markSkipped(1, 2)).thenAnswer(
      (_) async =>
          const Left(ServerFailure(statusCode: 404, message: 'Guest not found', errorCode: 'EventGuest.NotFound')),
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const EventGuestActionSubmitting(), isA<EventGuestActionError>()]),
    );

    unawaited(cubit.markSkipped(1, 2));
    await expectation;
    verifyNever(() => dataRefreshBus.notify(any()));
  });
}
