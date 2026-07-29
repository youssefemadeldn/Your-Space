import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/mock/mock_data_store.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/add_guests_action_cubit/add_guests_action_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/add_guests_action_cubit/add_guests_action_state.dart';

void main() {
  late MockDataStore store;
  late AddGuestsActionCubit cubit;

  setUp(() {
    store = MockDataStore()..simulatedLatency = Duration.zero;
    cubit = AddGuestsActionCubit(store);
  });

  tearDown(() => cubit.close());

  test('addPersons emits [Submitting, Success] with the bulk-add result', () async {
    final event = store.createEvent(name: 'Fresh Event');
    final personIds = store.people().take(2).map((p) => p.id).toList();

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const AddGuestsActionSubmitting(),
        isA<AddGuestsActionSuccess>().having((s) => s.result.addedCount, 'addedCount', 2),
      ]),
    );

    unawaited(cubit.addPersons(eventId: event.id, personIds: personIds));
    await expectation;
  });

  test('addGroup emits [Submitting, Success] adding the whole group', () async {
    final event = store.createEvent(name: 'Fresh Event 2');
    final group = store.groups().first;
    final peopleInGroup = store.people(groupId: group.id);

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const AddGuestsActionSubmitting(),
        isA<AddGuestsActionSuccess>().having(
          (s) => s.result.addedCount,
          'addedCount',
          peopleInGroup.length,
        ),
      ]),
    );

    unawaited(cubit.addGroup(eventId: event.id, groupId: group.id));
    await expectation;
  });
}
