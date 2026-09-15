import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/city.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/classification/domain/repositories/base_city_repository.dart';

import 'city_list_state.dart';

const _pageSize = 20;

/// City is local-first (CLAUDE.md Architecture rule 7, row 8.8): the list is
/// read from a reactive drift `Stream` via `watchCities()` — mirrors
/// `GroupsListCubit`'s `_subscribeToGroups` pattern. No `DataRefreshBus`
/// dependency — `DataScope.classification` was retired at row 8.20, once
/// Neighborhood (the last Classification entity) also became local-first and
/// no inline "add new" notification needed a cross-entity poke to trigger
/// `refresh()` anymore.
///
/// `neighborhoodCount` is server-computed (design doc §8) — not cached
/// locally, so it's fetched once per `load()`/`refresh()` via the existing
/// nested `getCities` endpoint (unchanged, still governorate-scoped) and
/// merged onto the locally-cached rows via `City.copyWith` before emitting.
@injectable
class CityListCubit extends Cubit<CityListState> {
  final CityRepository _cityRepository;
  Timer? _searchDebounce;
  StreamSubscription<List<City>>? _citiesSubscription;
  Map<int, int> _neighborhoodCounts = const {};

  CityListCubit(this._cityRepository) : super(const CityListInitial());

  Future<void> load(int governorateId) async {
    emit(const CityListLoading());
    _neighborhoodCounts = await _fetchNeighborhoodCounts(governorateId);
    await _subscribeToCities(governorateId: governorateId, search: null, limit: _pageSize);
  }

  /// Debounced — bound directly to every keystroke in the search field.
  void search(String query) {
    if (state is! CityListSuccess) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    final current = state;
    if (current is! CityListSuccess) return;
    await _subscribeToCities(
      governorateId: current.governorateId,
      search: query.isEmpty ? null : query,
      limit: _pageSize,
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! CityListSuccess || !current.hasNextPage || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    await _subscribeToCities(
      governorateId: current.governorateId,
      search: current.search,
      limit: current.limit + _pageSize,
      onError: (_) => emit(current.copyWith(
        isLoadingMore: false,
        loadMoreErrorMessage: core.failureToMessage(const CacheFailure()),
        loadMoreErrorId: current.loadMoreErrorId + 1,
      )),
    );
  }

  /// Re-fetches the counts and re-subscribes — the drift `Stream` already
  /// re-emits on upsert/tombstone, so this is mainly here to refresh
  /// `neighborhoodCount` (server-computed, design doc §8).
  Future<void> refresh() async {
    final current = state;
    if (current is! CityListSuccess) return;
    _neighborhoodCounts = await _fetchNeighborhoodCounts(current.governorateId);
    await _subscribeToCities(governorateId: current.governorateId, search: current.search, limit: current.limit);
  }

  /// Cancels any existing local subscription and resubscribes to
  /// `watchCities(governorateId: ..., search: search, limit: limit)`. Every
  /// emission also resolves `hasNextPage` via a one-shot `countCities` call
  /// before building the next [CityListSuccess], and merges the
  /// already-fetched [_neighborhoodCounts] onto each row. Mirrors
  /// `GroupsListCubit._subscribeToGroups`.
  Future<void> _subscribeToCities({
    required int governorateId,
    required String? search,
    required int limit,
    void Function(Object error)? onError,
  }) async {
    await _citiesSubscription?.cancel();
    final done = Completer<void>();

    void handleError(Object error) {
      if (onError != null) {
        onError(error);
      } else {
        emit(CityListError(core.failureToMessage(const CacheFailure())));
      }
      if (!done.isCompleted) done.complete();
    }

    _citiesSubscription =
        _cityRepository.watchCities(governorateId: governorateId, search: search, limit: limit).listen(
      (cities) async {
        try {
          final total = await _cityRepository.countCities(governorateId: governorateId, search: search);
          final withCounts = cities
              .map((c) => c.copyWith(neighborhoodCount: _neighborhoodCounts[c.id] ?? c.neighborhoodCount))
              .toList();
          emit(CityListSuccess(
            cities: withCounts,
            governorateId: governorateId,
            search: search,
            limit: limit,
            hasNextPage: cities.length < total,
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

  /// One-shot: `NeighborhoodCount` is server-computed (design doc §8), not
  /// cached locally. Reuses the existing nested `getCities` endpoint (still
  /// governorate-scoped, unchanged this row) purely to read each row's count
  /// — a bounded single page is enough given Classification's expected low
  /// cardinality per governorate. A failure here is swallowed: the local
  /// stream still renders, just without fresh counts until the next
  /// load/refresh.
  Future<Map<int, int>> _fetchNeighborhoodCounts(int governorateId) async {
    final result = await _cityRepository.getCities(governorateId: governorateId, pageIndex: 1, pageSize: 200);
    return result.fold((_) => const {}, (page) => {for (final c in page.items) c.id: c.neighborhoodCount});
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    _citiesSubscription?.cancel();
    return super.close();
  }
}
