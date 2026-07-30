import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/events/domain/entities/event_guest_status.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_guest_repository.dart';
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';

import 'event_guests_list_state.dart';

const _pageSize = 20;

@injectable
class EventGuestsListCubit extends Cubit<EventGuestsListState> {
  final EventGuestRepository _eventGuestRepository;
  final GroupRepository _groupRepository;

  EventGuestsListCubit(this._eventGuestRepository, this._groupRepository)
      : super(const EventGuestsListInitial());

  int? _eventId;

  Future<void> load(int eventId) async {
    _eventId = eventId;
    emit(const EventGuestsListLoading());
    final groupsResult = await _groupRepository.getGroups(pageIndex: 1, pageSize: 50);
    final groups = groupsResult.fold((_) => const <Group>[], (page) => page.items);
    final guestsResult =
        await _eventGuestRepository.getEventGuests(eventId, pageIndex: 1, pageSize: _pageSize);
    guestsResult.fold(
      (failure) => emit(EventGuestsListError(core.failureToMessage(failure))),
      (page) => emit(EventGuestsListSuccess(
        guests: page.items,
        groups: groups,
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
      )),
    );
  }

  Future<void> filterByStatus(EventGuestStatus? status) async {
    final current = state;
    if (current is! EventGuestsListSuccess) return;
    final result = await _eventGuestRepository.getEventGuests(
      _eventId!,
      groupId: current.selectedGroupId,
      status: status,
      pageIndex: 1,
      pageSize: _pageSize,
    );
    result.fold(
      (failure) => emit(EventGuestsListError(core.failureToMessage(failure))),
      (page) => emit(EventGuestsListSuccess(
        guests: page.items,
        groups: current.groups,
        selectedStatus: status,
        selectedGroupId: current.selectedGroupId,
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
      )),
    );
  }

  Future<void> filterByGroup(int? groupId) async {
    final current = state;
    if (current is! EventGuestsListSuccess) return;
    final result = await _eventGuestRepository.getEventGuests(
      _eventId!,
      groupId: groupId,
      status: current.selectedStatus,
      pageIndex: 1,
      pageSize: _pageSize,
    );
    result.fold(
      (failure) => emit(EventGuestsListError(core.failureToMessage(failure))),
      (page) => emit(EventGuestsListSuccess(
        guests: page.items,
        groups: current.groups,
        selectedStatus: current.selectedStatus,
        selectedGroupId: groupId,
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
      )),
    );
  }

  /// Re-queries page 1 without a `Loading` flash — used after a guest action
  /// (mark invited/skip/revert/remove) already ran its own submit-lifecycle.
  Future<void> reloadAfterAction() async {
    final current = state;
    if (current is! EventGuestsListSuccess) return;
    final result = await _eventGuestRepository.getEventGuests(
      _eventId!,
      groupId: current.selectedGroupId,
      status: current.selectedStatus,
      pageIndex: 1,
      pageSize: _pageSize,
    );
    result.fold(
      (failure) => emit(EventGuestsListError(core.failureToMessage(failure))),
      (page) => emit(EventGuestsListSuccess(
        guests: page.items,
        groups: current.groups,
        selectedStatus: current.selectedStatus,
        selectedGroupId: current.selectedGroupId,
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
      )),
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! EventGuestsListSuccess || !current.hasNextPage || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    final result = await _eventGuestRepository.getEventGuests(
      _eventId!,
      groupId: current.selectedGroupId,
      status: current.selectedStatus,
      pageIndex: current.pageIndex + 1,
      pageSize: _pageSize,
    );
    result.fold(
      (failure) => emit(current.copyWith(isLoadingMore: false)),
      (page) => emit(current.copyWith(
        guests: [...current.guests, ...page.items],
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
        isLoadingMore: false,
      )),
    );
  }
}
