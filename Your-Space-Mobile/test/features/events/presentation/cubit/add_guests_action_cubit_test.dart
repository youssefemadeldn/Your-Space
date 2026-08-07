import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/features/events/domain/entities/bulk_add_guests_result.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_guest_repository.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/add_guests_action_cubit/add_guests_action_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/add_guests_action_cubit/add_guests_action_state.dart';

class MockEventGuestRepository extends Mock implements EventGuestRepository {}

class MockDataRefreshBus extends Mock implements DataRefreshBus {}

void main() {
  late MockEventGuestRepository repository;
  late MockDataRefreshBus dataRefreshBus;
  late AddGuestsActionCubit cubit;

  setUp(() {
    repository = MockEventGuestRepository();
    dataRefreshBus = MockDataRefreshBus();
    cubit = AddGuestsActionCubit(repository, dataRefreshBus);
  });

  tearDown(() => cubit.close());

  test('addPersons emits [Submitting, Success] with the bulk-add result', () async {
    when(() => repository.addPersonsToEvent(eventId: 1, personIds: [1, 2])).thenAnswer(
      (_) async => const Right(BulkAddGuestsResult(requestedCount: 2, addedCount: 2, alreadyPresentCount: 0)),
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const AddGuestsActionSubmitting(personIds: [1, 2]),
        isA<AddGuestsActionSuccess>().having((s) => s.result.addedCount, 'addedCount', 2),
      ]),
    );

    unawaited(cubit.addPersons(eventId: 1, personIds: [1, 2]));
    await expectation;
    verify(() => dataRefreshBus.notify(DataScope.eventGuests)).called(1);
  });

  test('addGroup emits [Submitting, Success] adding the whole group', () async {
    when(() => repository.addGroupToEvent(eventId: 1, groupId: 3)).thenAnswer(
      (_) async => const Right(BulkAddGuestsResult(requestedCount: 4, addedCount: 4, alreadyPresentCount: 0)),
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const AddGuestsActionSubmitting(groupId: 3),
        isA<AddGuestsActionSuccess>().having((s) => s.result.addedCount, 'addedCount', 4),
      ]),
    );

    unawaited(cubit.addGroup(eventId: 1, groupId: 3));
    await expectation;
    verify(() => dataRefreshBus.notify(DataScope.eventGuests)).called(1);
  });

  // Regression test for the original bug: AddGuestsActionSubmitting used to carry no
  // identifier at all, so every button/row bound to the cubit lit up together no matter
  // which one was actually submitting. Each emission must carry only its own action's
  // identifier — never both, and never neither while genuinely submitting.
  test('addGroup Submitting state carries only its own groupId, never a personIds value', () async {
    when(() => repository.addGroupToEvent(eventId: 1, groupId: 3)).thenAnswer(
      (_) async => const Right(BulkAddGuestsResult(requestedCount: 1, addedCount: 1, alreadyPresentCount: 0)),
    );

    final submittingStates = <AddGuestsActionSubmitting>[];
    final sub = cubit.stream.listen((state) {
      if (state is AddGuestsActionSubmitting) submittingStates.add(state);
    });

    await cubit.addGroup(eventId: 1, groupId: 3);
    await sub.cancel();

    expect(submittingStates, hasLength(1));
    expect(submittingStates.single.groupId, 3);
    expect(submittingStates.single.personIds, isNull);
  });

  test('addPersons Submitting state carries only its own personIds, never a groupId', () async {
    when(() => repository.addPersonsToEvent(eventId: 1, personIds: [1, 2])).thenAnswer(
      (_) async => const Right(BulkAddGuestsResult(requestedCount: 2, addedCount: 2, alreadyPresentCount: 0)),
    );

    final submittingStates = <AddGuestsActionSubmitting>[];
    final sub = cubit.stream.listen((state) {
      if (state is AddGuestsActionSubmitting) submittingStates.add(state);
    });

    await cubit.addPersons(eventId: 1, personIds: [1, 2]);
    await sub.cancel();

    expect(submittingStates, hasLength(1));
    expect(submittingStates.single.personIds, [1, 2]);
    expect(submittingStates.single.groupId, isNull);
  });
}
