import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/events/domain/entities/event.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_repository.dart';

import 'events_list_state.dart';

const _pageSize = 20;

/// Event is local-first from row 9.2: the list is read from a reactive
/// drift `Stream` via `watchEvents()` — mirrors `CityListCubit._subscribeToCities`.
///
/// `totalGuestCount` is a field on the cached `Event` row itself, but it's
/// only ever refreshed when the server is actually pulled (Tier 1 upsert or
/// Tier 3 pull) — it does not update locally just because a guest changed
/// elsewhere. Until EventGuest's own migration lands (row 9.9/9.10) and
/// guest mutations move off `DataRefreshBus` entirely, this cubit still
/// listens for `DataScope.events`/`DataScope.eventGuests` and triggers a
/// background `refreshEvents()` pull on it (fire-and-forget — the drift
/// `Stream` picks up the refreshed count once the pull lands). This
/// dependency is expected to be removed once row 9.10 finishes retiring
/// those two scopes.
@injectable
class EventsListCubit extends Cubit<EventsListState> {
  final EventRepository _eventRepository;
  final DataRefreshBus _dataRefreshBus;
  Timer? _searchDebounce;
  StreamSubscription<List<Event>>? _eventsSubscription;
  late final StreamSubscription<DataScope> _refreshSubscription;

  EventsListCubit(this._eventRepository, this._dataRefreshBus) : super(const EventsListInitial()) {
    _refreshSubscription = _dataRefreshBus.stream.listen((scope) {
      if (scope == DataScope.events || scope == DataScope.eventGuests) {
        unawaited(_eventRepository.refreshEvents());
      }
    });
  }

  Future<void> load() async {
    emit(const EventsListLoading());
    await _subscribeToEvents(search: null, limit: _pageSize);
  }

  /// Debounced — bound directly to every keystroke in the search field.
  void search(String query) {
    if (state is! EventsListSuccess) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    final current = state;
    if (current is! EventsListSuccess) return;
    await _subscribeToEvents(search: query.isEmpty ? null : query, limit: _pageSize);
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! EventsListSuccess || !current.hasNextPage || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    await _subscribeToEvents(search: current.search, limit: current.limit + _pageSize);
  }

  /// Pull-to-refresh: re-subscribes (the drift `Stream` already re-emits on
  /// upsert/tombstone on its own) and kicks a background server pull so
  /// `totalGuestCount`/any other server-only field is fresh.
  Future<void> refresh() async {
    final current = state;
    if (current is! EventsListSuccess) return;
    unawaited(_eventRepository.refreshEvents());
    await _subscribeToEvents(search: current.search, limit: current.limit);
  }

  /// Cancels any existing local subscription and resubscribes to
  /// `watchEvents(search: search, limit: limit)`. Every emission also
  /// resolves `hasNextPage` via a one-shot `countEvents` call before
  /// building the next [EventsListSuccess]. Mirrors
  /// `CityListCubit._subscribeToCities`.
  Future<void> _subscribeToEvents({required String? search, required int limit}) async {
    await _eventsSubscription?.cancel();
    final done = Completer<void>();

    void handleError(Object error) {
      emit(EventsListError(core.failureToMessage(const CacheFailure())));
      if (!done.isCompleted) done.complete();
    }

    _eventsSubscription = _eventRepository.watchEvents(search: search, limit: limit).listen(
      (events) async {
        try {
          final total = await _eventRepository.countEvents(search: search);
          emit(EventsListSuccess(
            events,
            search: search,
            limit: limit,
            hasNextPage: events.length < total,
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
    _searchDebounce?.cancel();
    _eventsSubscription?.cancel();
    _refreshSubscription.cancel();
    return super.close();
  }
}
