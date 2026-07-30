import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/features/events/domain/entities/bulk_add_guests_result.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_guest_repository.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/add_guests_action_cubit/add_guests_action_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/add_guests_action_cubit/add_guests_action_state.dart';

class MockEventGuestRepository extends Mock implements EventGuestRepository {}

void main() {
  late MockEventGuestRepository repository;
  late AddGuestsActionCubit cubit;

  setUp(() {
    repository = MockEventGuestRepository();
    cubit = AddGuestsActionCubit(repository);
  });

  tearDown(() => cubit.close());

  test('addPersons emits [Submitting, Success] with the bulk-add result', () async {
    when(() => repository.addPersonsToEvent(eventId: 1, personIds: [1, 2])).thenAnswer(
      (_) async => const Right(BulkAddGuestsResult(requestedCount: 2, addedCount: 2, alreadyPresentCount: 0)),
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const AddGuestsActionSubmitting(),
        isA<AddGuestsActionSuccess>().having((s) => s.result.addedCount, 'addedCount', 2),
      ]),
    );

    unawaited(cubit.addPersons(eventId: 1, personIds: [1, 2]));
    await expectation;
  });

  test('addGroup emits [Submitting, Success] adding the whole group', () async {
    when(() => repository.addGroupToEvent(eventId: 1, groupId: 3)).thenAnswer(
      (_) async => const Right(BulkAddGuestsResult(requestedCount: 4, addedCount: 4, alreadyPresentCount: 0)),
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const AddGuestsActionSubmitting(),
        isA<AddGuestsActionSuccess>().having((s) => s.result.addedCount, 'addedCount', 4),
      ]),
    );

    unawaited(cubit.addGroup(eventId: 1, groupId: 3));
    await expectation;
  });
}
