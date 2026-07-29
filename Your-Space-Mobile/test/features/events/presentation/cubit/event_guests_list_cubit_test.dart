import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/mock/entities/event_guest_status.dart';
import 'package:your_space_mobile/core/mock/mock_data_store.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/event_guests_list_cubit/event_guests_list_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/event_guests_list_cubit/event_guests_list_state.dart';

void main() {
  late MockDataStore store;
  late EventGuestsListCubit cubit;

  setUp(() {
    store = MockDataStore()..simulatedLatency = Duration.zero;
    cubit = EventGuestsListCubit(store);
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] with all guests for the event', () async {
    final event = store.events().first;

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const EventGuestsListLoading(),
        isA<EventGuestsListSuccess>()
            .having((s) => s.guests.length, 'guests.length', store.eventGuests(event.id).length),
      ]),
    );

    unawaited(cubit.load(event.id));
    await expectation;
  });

  test('filterByStatus narrows the list and tracks selectedStatus', () async {
    final event = store.events().first;
    await cubit.load(event.id);

    final expectation = expectLater(
      cubit.stream,
      emits(
        isA<EventGuestsListSuccess>()
            .having((s) => s.selectedStatus, 'selectedStatus', EventGuestStatus.invited)
            .having((s) => s.guests.every((g) => g.status == EventGuestStatus.invited), 'all invited', true),
      ),
    );

    cubit.filterByStatus(EventGuestStatus.invited);
    await expectation;
  });

  test('reloadAfterAction re-queries without emitting a Loading state', () async {
    final event = store.events().first;
    await cubit.load(event.id);

    // Cubit.emit() skips re-emitting an Equatable-equal state, so the store
    // must actually change first — otherwise reloadAfterAction's recomputed
    // state is identical to the current one and nothing would be emitted at
    // all (not even a Loading state, which is itself part of what this test
    // wants to prove, but requires a real change to observe).
    final guest = store.eventGuests(event.id).firstWhere((g) => g.status == EventGuestStatus.notInvited);
    store.markSkipped(guest.id);

    // emits() matches exactly the next single emission — if reloadAfterAction
    // emitted Loading first, this would fail on that mismatch.
    final expectation = expectLater(cubit.stream, emits(isA<EventGuestsListSuccess>()));
    cubit.reloadAfterAction();
    await expectation;
  });
}
