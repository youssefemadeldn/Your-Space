import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/mock/entities/event.dart';

sealed class EventsListState extends Equatable {
  const EventsListState();
  @override
  List<Object?> get props => const [];
}

final class EventsListInitial extends EventsListState {
  const EventsListInitial();
}

final class EventsListLoading extends EventsListState {
  const EventsListLoading();
}

final class EventsListSuccess extends EventsListState {
  final List<Event> events;
  const EventsListSuccess(this.events);
  @override
  List<Object?> get props => [events];
}

final class EventsListError extends EventsListState {
  final String message;
  const EventsListError(this.message);
  @override
  List<Object?> get props => [message];
}
