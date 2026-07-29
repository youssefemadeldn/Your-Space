import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/mock/mock_data_store.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/add_guests_list_cubit/add_guests_list_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/add_guests_list_cubit/add_guests_list_state.dart';

void main() {
  late MockDataStore store;
  late AddGuestsListCubit cubit;

  setUp(() {
    store = MockDataStore()..simulatedLatency = Duration.zero;
    cubit = AddGuestsListCubit(store);
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] excluding persons already on the guest list', () async {
    final event = store.events().firstWhere((e) => e.name == "Sara's Birthday");
    final existingIds = store.eventGuests(event.id).map((g) => g.personId).toSet();

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const AddGuestsListLoading(),
        isA<AddGuestsListSuccess>().having(
          (s) => s.availablePeople.any((p) => existingIds.contains(p.id)),
          'no overlap with existing guests',
          false,
        ),
      ]),
    );

    unawaited(cubit.load(event.id));
    await expectation;
  });

  test('availableCountForGroup counts only available (not-yet-added) people', () async {
    final event = store.events().firstWhere((e) => e.name == "Sara's Birthday");
    await cubit.load(event.id);
    final state = cubit.state as AddGuestsListSuccess;
    final group = store.groups().first;

    final expectedCount = state.availablePeople.where((p) => p.groupId == group.id).length;
    expect(state.availableCountForGroup(group.id), expectedCount);
  });
}
