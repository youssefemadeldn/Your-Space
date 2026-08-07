import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/invite_method.dart';
import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/events/domain/repositories/base_event_guest_repository.dart';

import 'event_guest_action_state.dart';

/// Every status transition is unconditional (no state-machine guard),
/// matching the backend brief's documented behavior — "Mark invited",
/// "Skip", "Revert", and "Remove" are always available regardless of the
/// guest's current status.
@injectable
class EventGuestActionCubit extends Cubit<EventGuestActionState> {
  final EventGuestRepository _eventGuestRepository;
  final DataRefreshBus _dataRefreshBus;

  EventGuestActionCubit(this._eventGuestRepository, this._dataRefreshBus)
      : super(const EventGuestActionInitial());

  Future<void> markInvited(int eventId, int guestId, {required InviteMethod inviteMethod}) async {
    emit(const EventGuestActionSubmitting());
    final result =
        await _eventGuestRepository.markInvited(eventId, guestId, inviteMethod: inviteMethod);
    result.fold(
      (failure) => emit(EventGuestActionError(core.failureToMessage(failure))),
      (_) {
        _dataRefreshBus.notify(DataScope.eventGuests);
        emit(const EventGuestActionSuccess());
      },
    );
  }

  Future<void> markSkipped(int eventId, int guestId) async {
    emit(const EventGuestActionSubmitting());
    final result = await _eventGuestRepository.markSkipped(eventId, guestId);
    result.fold(
      (failure) => emit(EventGuestActionError(core.failureToMessage(failure))),
      (_) {
        _dataRefreshBus.notify(DataScope.eventGuests);
        emit(const EventGuestActionSuccess());
      },
    );
  }

  Future<void> revert(int eventId, int guestId) async {
    emit(const EventGuestActionSubmitting());
    final result = await _eventGuestRepository.revertGuest(eventId, guestId);
    result.fold(
      (failure) => emit(EventGuestActionError(core.failureToMessage(failure))),
      (_) {
        _dataRefreshBus.notify(DataScope.eventGuests);
        emit(const EventGuestActionSuccess());
      },
    );
  }

  Future<void> remove(int eventId, int guestId) async {
    emit(const EventGuestActionSubmitting());
    final result = await _eventGuestRepository.removeGuest(eventId, guestId);
    result.fold(
      (failure) => emit(EventGuestActionError(core.failureToMessage(failure))),
      (_) {
        _dataRefreshBus.notify(DataScope.eventGuests);
        emit(const EventGuestActionSuccess());
      },
    );
  }
}
