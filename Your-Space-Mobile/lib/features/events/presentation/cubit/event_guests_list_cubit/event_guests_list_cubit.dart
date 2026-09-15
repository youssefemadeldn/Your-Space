import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/events/domain/entities/event_guest.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest_status.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_guest_repository.dart';
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';

import 'event_guests_list_state.dart';

const _pageSize = 20;

/// EventGuest is local-first from row 9.8: the list is read from a reactive
/// drift `Stream` via `watchEventGuests()` — mirrors
/// `CityListCubit._subscribeToCities`. No `DataRefreshBus` dependency —
/// `EventGuestActionCubit`'s mutations already write straight into drift via
/// the outbox (row 9.9), so every open `watchEventGuests` stream sees the
/// change directly — the screen no longer calls a manual reload after an
/// action succeeds.
@injectable
class EventGuestsListCubit extends Cubit<EventGuestsListState> {
  final EventGuestRepository _eventGuestRepository;
  final GroupRepository _groupRepository;
  StreamSubscription<List<EventGuest>>? _guestsSubscription;

  EventGuestsListCubit(this._eventGuestRepository, this._groupRepository)
      : super(const EventGuestsListInitial());

  int? _eventId;

  Future<void> load(int eventId) async {
    _eventId = eventId;
    emit(const EventGuestsListLoading());
    final groupsResult = await _groupRepository.getGroups(pageIndex: 1, pageSize: 50);
    final groups = groupsResult.fold((_) => const <Group>[], (page) => page.items);
    await _subscribeToGuests(groups: groups, groupId: null, status: null, limit: _pageSize);
  }

  Future<void> filterByStatus(EventGuestStatus? status) async {
    final current = state;
    if (current is! EventGuestsListSuccess) return;
    await _subscribeToGuests(
      groups: current.groups,
      groupId: current.selectedGroupId,
      status: status,
      limit: _pageSize,
    );
  }

  Future<void> filterByGroup(int? groupId) async {
    final current = state;
    if (current is! EventGuestsListSuccess) return;
    await _subscribeToGuests(
      groups: current.groups,
      groupId: groupId,
      status: current.selectedStatus,
      limit: _pageSize,
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! EventGuestsListSuccess || !current.hasNextPage || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    await _subscribeToGuests(
      groups: current.groups,
      groupId: current.selectedGroupId,
      status: current.selectedStatus,
      limit: current.limit + _pageSize,
    );
  }

  /// Cancels any existing local subscription and resubscribes to
  /// `watchEventGuests(eventId: ..., groupId: groupId, status: status,
  /// limit: limit)`. Every emission also resolves `hasNextPage` via a
  /// one-shot `countEventGuests` call before building the next
  /// [EventGuestsListSuccess]. Mirrors `CityListCubit._subscribeToCities`.
  Future<void> _subscribeToGuests({
    required List<Group> groups,
    required int? groupId,
    required EventGuestStatus? status,
    required int limit,
  }) async {
    await _guestsSubscription?.cancel();
    final done = Completer<void>();
    final eventId = _eventId!;

    void handleError(Object error) {
      emit(EventGuestsListError(core.failureToMessage(const CacheFailure())));
      if (!done.isCompleted) done.complete();
    }

    _guestsSubscription = _eventGuestRepository
        .watchEventGuests(eventId: eventId, groupId: groupId, status: status, limit: limit)
        .listen(
      (guests) async {
        try {
          final total = await _eventGuestRepository.countEventGuests(
            eventId: eventId,
            groupId: groupId,
            status: status,
          );
          emit(EventGuestsListSuccess(
            guests: guests,
            groups: groups,
            selectedStatus: status,
            selectedGroupId: groupId,
            limit: limit,
            hasNextPage: guests.length < total,
          ));
          if (!done.isCompleted) done.complete();
        } catch (error) {
          handleError(error);
        }
      },
      onError: (Object error) => handleError(error),
    );
    await done.future;
  }

  @override
  Future<void> close() {
    _guestsSubscription?.cancel();
    return super.close();
  }
}
