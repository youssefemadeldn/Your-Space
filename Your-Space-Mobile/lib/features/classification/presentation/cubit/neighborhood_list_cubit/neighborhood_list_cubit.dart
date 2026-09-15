import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/neighborhood.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/classification/domain/repositories/base_neighborhood_repository.dart';

import 'neighborhood_list_state.dart';

const _pageSize = 20;

/// Neighborhood is local-first (CLAUDE.md Architecture rule 7, row 8.20): the
/// list is read from a reactive drift `Stream` via `watchNeighborhoods()` —
/// mirrors `CityListCubit`'s `_subscribeToCities` pattern. Neighborhood is
/// the last Classification entity to migrate, so unlike City/SubGroup this
/// cubit never had a `DataScope.classification` listener to retire here —
/// row 8.20 is the step that deletes the scope entirely, and this file's own
/// migration is exactly what makes that deletion safe.
///
/// `personCount` is server-computed (design doc §8) — not cached locally, so
/// it's fetched once per `load()`/`refresh()` via the existing nested
/// `getNeighborhoods` endpoint (unchanged, still city-scoped) and merged onto
/// the locally-cached rows via `Neighborhood.copyWith` before emitting.
@injectable
class NeighborhoodListCubit extends Cubit<NeighborhoodListState> {
  final NeighborhoodRepository _neighborhoodRepository;
  Timer? _searchDebounce;
  StreamSubscription<List<Neighborhood>>? _neighborhoodsSubscription;
  Map<int, int> _personCounts = const {};

  NeighborhoodListCubit(this._neighborhoodRepository) : super(const NeighborhoodListInitial());

  Future<void> load(int cityId) async {
    emit(const NeighborhoodListLoading());
    _personCounts = await _fetchPersonCounts(cityId);
    await _subscribeToNeighborhoods(cityId: cityId, search: null, limit: _pageSize);
  }

  /// Debounced — bound directly to every keystroke in the search field.
  void search(String query) {
    if (state is! NeighborhoodListSuccess) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    final current = state;
    if (current is! NeighborhoodListSuccess) return;
    await _subscribeToNeighborhoods(
      cityId: current.cityId,
      search: query.isEmpty ? null : query,
      limit: _pageSize,
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! NeighborhoodListSuccess || !current.hasNextPage || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    await _subscribeToNeighborhoods(
      cityId: current.cityId,
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
  /// `personCount` (server-computed, design doc §8).
  Future<void> refresh() async {
    final current = state;
    if (current is! NeighborhoodListSuccess) return;
    _personCounts = await _fetchPersonCounts(current.cityId);
    await _subscribeToNeighborhoods(cityId: current.cityId, search: current.search, limit: current.limit);
  }

  /// Cancels any existing local subscription and resubscribes to
  /// `watchNeighborhoods(cityId: ..., search: search, limit: limit)`. Every
  /// emission also resolves `hasNextPage` via a one-shot `countNeighborhoods`
  /// call before building the next [NeighborhoodListSuccess], and merges the
  /// already-fetched [_personCounts] onto each row. Mirrors
  /// `CityListCubit._subscribeToCities`.
  Future<void> _subscribeToNeighborhoods({
    required int cityId,
    required String? search,
    required int limit,
    void Function(Object error)? onError,
  }) async {
    await _neighborhoodsSubscription?.cancel();
    final done = Completer<void>();

    void handleError(Object error) {
      if (onError != null) {
        onError(error);
      } else {
        emit(NeighborhoodListError(core.failureToMessage(const CacheFailure())));
      }
      if (!done.isCompleted) done.complete();
    }

    _neighborhoodsSubscription =
        _neighborhoodRepository.watchNeighborhoods(cityId: cityId, search: search, limit: limit).listen(
      (neighborhoods) async {
        try {
          final total = await _neighborhoodRepository.countNeighborhoods(cityId: cityId, search: search);
          final withCounts = neighborhoods
              .map((n) => n.copyWith(personCount: _personCounts[n.id] ?? n.personCount))
              .toList();
          emit(NeighborhoodListSuccess(
            neighborhoods: withCounts,
            cityId: cityId,
            search: search,
            limit: limit,
            hasNextPage: neighborhoods.length < total,
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

  /// One-shot: `PersonCount` is server-computed (design doc §8), not cached
  /// locally. Reuses the existing nested `getNeighborhoods` endpoint (still
  /// city-scoped, unchanged this row) purely to read each row's count — a
  /// bounded single page is enough given Classification's expected low
  /// cardinality per city. A failure here is swallowed: the local stream
  /// still renders, just without fresh counts until the next load/refresh.
  Future<Map<int, int>> _fetchPersonCounts(int cityId) async {
    final result = await _neighborhoodRepository.getNeighborhoods(cityId: cityId, pageIndex: 1, pageSize: 200);
    return result.fold((_) => const {}, (page) => {for (final n in page.items) n.id: n.personCount});
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    _neighborhoodsSubscription?.cancel();
    return super.close();
  }
}
