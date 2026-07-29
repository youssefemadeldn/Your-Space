import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/mock/entities/event_guest_status.dart';
import 'package:your_space_mobile/core/mock/mock_data_store.dart';

import 'event_guests_list_state.dart';

@injectable
class EventGuestsListCubit extends Cubit<EventGuestsListState> {
  final MockDataStore _store;

  EventGuestsListCubit(this._store) : super(const EventGuestsListInitial());

  int? _eventId;

  Future<void> load(int eventId) async {
    _eventId = eventId;
    emit(const EventGuestsListLoading());
    await Future.delayed(_store.simulatedLatency);
    emit(EventGuestsListSuccess(guests: _store.eventGuests(eventId), groups: _store.groups()));
  }

  void filterByStatus(EventGuestStatus? status) {
    final current = state;
    if (current is! EventGuestsListSuccess) return;
    emit(EventGuestsListSuccess(
      guests: _store.eventGuests(_eventId!, groupId: current.selectedGroupId, status: status),
      groups: current.groups,
      selectedStatus: status,
      selectedGroupId: current.selectedGroupId,
    ));
  }

  void filterByGroup(int? groupId) {
    final current = state;
    if (current is! EventGuestsListSuccess) return;
    emit(EventGuestsListSuccess(
      guests: _store.eventGuests(_eventId!, groupId: groupId, status: current.selectedStatus),
      groups: current.groups,
      selectedStatus: current.selectedStatus,
      selectedGroupId: groupId,
    ));
  }

  /// Re-queries the store without a `Loading` flash — used after a guest
  /// action (mark invited/skip/revert/remove) already ran its own
  /// submit-lifecycle; a second spinner on the list itself would be redundant.
  void reloadAfterAction() {
    final current = state;
    if (current is! EventGuestsListSuccess) return;
    emit(EventGuestsListSuccess(
      guests: _store.eventGuests(_eventId!, groupId: current.selectedGroupId, status: current.selectedStatus),
      groups: current.groups,
      selectedStatus: current.selectedStatus,
      selectedGroupId: current.selectedGroupId,
    ));
  }
}
