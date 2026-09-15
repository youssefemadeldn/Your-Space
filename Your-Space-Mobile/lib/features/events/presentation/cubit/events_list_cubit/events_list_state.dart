import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/features/events/domain/entities/event.dart';

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
  final String? search;

  /// How many rows the local `watchEvents` query is currently asking for
  /// (grows by the page size on `loadMore()`) — a local read window, not a
  /// server page index (Tier 1, design doc §3).
  final int limit;
  final bool hasNextPage;
  final bool isLoadingMore;

  const EventsListSuccess(
    this.events, {
    this.search,
    required this.limit,
    required this.hasNextPage,
    this.isLoadingMore = false,
  });

  EventsListSuccess copyWith({
    List<Event>? events,
    int? limit,
    bool? hasNextPage,
    bool? isLoadingMore,
  }) =>
      EventsListSuccess(
        events ?? this.events,
        search: search,
        limit: limit ?? this.limit,
        hasNextPage: hasNextPage ?? this.hasNextPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

  @override
  List<Object?> get props => [events, search, limit, hasNextPage, isLoadingMore];
}

final class EventsListError extends EventsListState {
  final String message;
  const EventsListError(this.message);
  @override
  List<Object?> get props => [message];
}
