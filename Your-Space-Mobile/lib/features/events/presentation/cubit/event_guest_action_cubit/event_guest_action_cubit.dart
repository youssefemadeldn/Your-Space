import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/mock/entities/invite_method.dart';
import 'package:your_space_mobile/core/mock/mock_data_store.dart';

import 'event_guest_action_state.dart';

/// Every status transition is unconditional (no state-machine guard),
/// matching the backend brief's documented behavior — "Mark invited",
/// "Skip", "Revert", and "Remove" are always available regardless of the
/// guest's current status.
@injectable
class EventGuestActionCubit extends Cubit<EventGuestActionState> {
  final MockDataStore _store;

  EventGuestActionCubit(this._store) : super(const EventGuestActionInitial());

  Future<void> markInvited(int guestId, {required InviteMethod inviteMethod}) async {
    emit(const EventGuestActionSubmitting());
    await Future.delayed(_store.simulatedLatency);
    _store.markInvited(guestId, inviteMethod: inviteMethod);
    emit(const EventGuestActionSuccess());
  }

  Future<void> markSkipped(int guestId) async {
    emit(const EventGuestActionSubmitting());
    await Future.delayed(_store.simulatedLatency);
    _store.markSkipped(guestId);
    emit(const EventGuestActionSuccess());
  }

  Future<void> revert(int guestId) async {
    emit(const EventGuestActionSubmitting());
    await Future.delayed(_store.simulatedLatency);
    _store.revertGuest(guestId);
    emit(const EventGuestActionSuccess());
  }

  Future<void> remove(int guestId) async {
    emit(const EventGuestActionSubmitting());
    await Future.delayed(_store.simulatedLatency);
    _store.removeGuest(guestId);
    emit(const EventGuestActionSuccess());
  }
}
