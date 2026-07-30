import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest_status.dart';

sealed class EventGuestsListState extends Equatable {
  const EventGuestsListState();
  @override
  List<Object?> get props => const [];
}

final class EventGuestsListInitial extends EventGuestsListState {
  const EventGuestsListInitial();
}

final class EventGuestsListLoading extends EventGuestsListState {
  const EventGuestsListLoading();
}

final class EventGuestsListSuccess extends EventGuestsListState {
  final List<EventGuest> guests;
  final List<Group> groups;
  final EventGuestStatus? selectedStatus;
  final int? selectedGroupId;
  final int pageIndex;
  final bool hasNextPage;
  final bool isLoadingMore;

  const EventGuestsListSuccess({
    required this.guests,
    required this.groups,
    this.selectedStatus,
    this.selectedGroupId,
    required this.pageIndex,
    required this.hasNextPage,
    this.isLoadingMore = false,
  });

  EventGuestsListSuccess copyWith({
    List<EventGuest>? guests,
    int? pageIndex,
    bool? hasNextPage,
    bool? isLoadingMore,
  }) =>
      EventGuestsListSuccess(
        guests: guests ?? this.guests,
        groups: groups,
        selectedStatus: selectedStatus,
        selectedGroupId: selectedGroupId,
        pageIndex: pageIndex ?? this.pageIndex,
        hasNextPage: hasNextPage ?? this.hasNextPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

  @override
  List<Object?> get props =>
      [guests, groups, selectedStatus, selectedGroupId, pageIndex, hasNextPage, isLoadingMore];
}

final class EventGuestsListError extends EventGuestsListState {
  final String message;
  const EventGuestsListError(this.message);
  @override
  List<Object?> get props => [message];
}
