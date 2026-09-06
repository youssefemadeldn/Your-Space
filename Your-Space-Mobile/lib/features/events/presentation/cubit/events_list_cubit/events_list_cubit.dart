import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/events/domain/repositories/base_event_repository.dart';

import 'events_list_state.dart';

const _pageSize = 20;

@injectable
class EventsListCubit extends Cubit<EventsListState> {
  final EventRepository _eventRepository;
  final DataRefreshBus _dataRefreshBus;
  Timer? _searchDebounce;
  late final StreamSubscription<DataScope> _refreshSubscription;

  EventsListCubit(this._eventRepository, this._dataRefreshBus) : super(const EventsListInitial()) {
    _refreshSubscription = _dataRefreshBus.stream.listen((scope) {
      if (scope == DataScope.events || scope == DataScope.eventGuests) refresh();
    });
  }

  Future<void> load() async {
    emit(const EventsListLoading());
    final result = await _eventRepository.getEvents(pageIndex: 1, pageSize: _pageSize);
    result.fold(
      (failure) => emit(EventsListError(core.failureToMessage(failure))),
      (page) => emit(EventsListSuccess(page.items, pageIndex: page.pageIndex, hasNextPage: page.hasNextPage)),
    );
  }

  /// Debounced — bound directly to every keystroke in the search field.
  void search(String query) {
    if (state is! EventsListSuccess) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    final search = query.isEmpty ? null : query;
    final result = await _eventRepository.getEvents(search: search, pageIndex: 1, pageSize: _pageSize);
    result.fold(
      (failure) => emit(EventsListError(core.failureToMessage(failure))),
      (page) => emit(EventsListSuccess(
        page.items,
        search: search,
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
      )),
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! EventsListSuccess || !current.hasNextPage || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    final result = await _eventRepository.getEvents(
      search: current.search,
      pageIndex: current.pageIndex + 1,
      pageSize: _pageSize,
    );
    result.fold(
      (failure) => emit(current.copyWith(isLoadingMore: false)),
      (page) => emit(current.copyWith(
        events: [...current.events, ...page.items],
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
        isLoadingMore: false,
      )),
    );
  }

  /// Re-fetches page 1 with the current search, without a `Loading` flash —
  /// triggered by [DataRefreshBus] on `events` (event fields changed) or
  /// `eventGuests` (a guest was added/removed, changing `totalGuestCount`),
  /// and by pull-to-refresh. Keeps the last-good list on a background
  /// failure rather than replacing it with an error screen.
  Future<void> refresh() async {
    final current = state;
    if (current is! EventsListSuccess) return;
    final result = await _eventRepository.getEvents(search: current.search, pageIndex: 1, pageSize: _pageSize);
    result.fold(
      (_) {},
      (page) => emit(current.copyWith(events: page.items, pageIndex: page.pageIndex, hasNextPage: page.hasNextPage)),
    );
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    _refreshSubscription.cancel();
    return super.close();
  }
}
