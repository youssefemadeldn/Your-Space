import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/mock/entities/event_guest_status.dart';
import 'package:your_space_mobile/core/mock/entities/invite_method.dart';
import 'package:your_space_mobile/core/mock/mock_data_store.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/event_guest_action_cubit/event_guest_action_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/event_guest_action_cubit/event_guest_action_state.dart';

void main() {
  late MockDataStore store;
  late EventGuestActionCubit cubit;

  setUp(() {
    store = MockDataStore()..simulatedLatency = Duration.zero;
    cubit = EventGuestActionCubit(store);
  });

  tearDown(() => cubit.close());

  test('markInvited emits [Submitting, Success] and updates the store', () async {
    final event = store.events().first;
    final guest = store.eventGuests(event.id).firstWhere((g) => g.status == EventGuestStatus.notInvited);

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const EventGuestActionSubmitting(), const EventGuestActionSuccess()]),
    );

    unawaited(cubit.markInvited(guest.id, inviteMethod: InviteMethod.whatsApp));
    await expectation;

    expect(
      store.eventGuests(event.id).firstWhere((g) => g.id == guest.id).status,
      EventGuestStatus.invited,
    );
  });

  test('remove emits [Submitting, Success] and deletes the guest row', () async {
    final event = store.events().first;
    final guest = store.eventGuests(event.id).first;
    final countBefore = store.eventGuests(event.id).length;

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const EventGuestActionSubmitting(), const EventGuestActionSuccess()]),
    );

    unawaited(cubit.remove(guest.id));
    await expectation;

    expect(store.eventGuests(event.id), hasLength(countBefore - 1));
  });
}
