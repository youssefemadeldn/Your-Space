import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/mock/entities/event_guest.dart';
import 'package:your_space_mobile/core/mock/entities/event_guest_status.dart';
import 'package:your_space_mobile/core/mock/entities/group.dart';

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

  const EventGuestsListSuccess({
    required this.guests,
    required this.groups,
    this.selectedStatus,
    this.selectedGroupId,
  });

  @override
  List<Object?> get props => [guests, groups, selectedStatus, selectedGroupId];
}

final class EventGuestsListError extends EventGuestsListState {
  final String message;
  const EventGuestsListError(this.message);
  @override
  List<Object?> get props => [message];
}
