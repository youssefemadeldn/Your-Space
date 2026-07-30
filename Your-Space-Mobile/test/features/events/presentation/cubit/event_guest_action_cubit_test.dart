import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/invite_method.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest_status.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_guest_repository.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/event_guest_action_cubit/event_guest_action_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/event_guest_action_cubit/event_guest_action_state.dart';

class MockEventGuestRepository extends Mock implements EventGuestRepository {}

void main() {
  late MockEventGuestRepository repository;
  late EventGuestActionCubit cubit;

  setUp(() {
    repository = MockEventGuestRepository();
    cubit = EventGuestActionCubit(repository);
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
  });

  test('remove emits [Submitting, Success]', () async {
    when(() => repository.removeGuest(1, 2)).thenAnswer((_) async => const Right(unit));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const EventGuestActionSubmitting(), const EventGuestActionSuccess()]),
    );

    unawaited(cubit.remove(1, 2));
    await expectation;
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
  });
}
