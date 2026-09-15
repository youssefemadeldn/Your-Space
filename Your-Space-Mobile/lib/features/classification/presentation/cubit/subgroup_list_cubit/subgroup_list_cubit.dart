import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/subgroup.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/classification/domain/repositories/base_subgroup_repository.dart';

import 'subgroup_list_state.dart';

const _pageSize = 20;

/// SubGroup is local-first (CLAUDE.md Architecture rule 7, row 8.14): the
/// list is read from a reactive drift `Stream` via `watchSubGroups()` —
/// mirrors `CityListCubit`'s `_subscribeToCities` pattern. No
/// `DataRefreshBus` dependency — `DataScope.classification` was retired at
/// row 8.20, once Neighborhood (the last Classification entity) also became
/// local-first and no inline "add new" notification needed a cross-entity
/// poke to trigger `refresh()` anymore.
///
/// `personCount` is server-computed (design doc §8) — not cached locally,
/// so it's fetched once per `load()`/`refresh()` via the existing nested
/// `getSubGroups` endpoint (unchanged, still group-scoped) and merged onto
/// the locally-cached rows via `SubGroup.copyWith` before emitting.
@injectable
class SubGroupListCubit extends Cubit<SubGroupListState> {
  final SubGroupRepository _subGroupRepository;
  Timer? _searchDebounce;
  StreamSubscription<List<SubGroup>>? _subGroupsSubscription;
  Map<int, int> _personCounts = const {};

  SubGroupListCubit(this._subGroupRepository) : super(const SubGroupListInitial());

  Future<void> load(int groupId) async {
    emit(const SubGroupListLoading());
    _personCounts = await _fetchPersonCounts(groupId);
    await _subscribeToSubGroups(groupId: groupId, search: null, limit: _pageSize);
  }

  /// Debounced — bound directly to every keystroke in the search field.
  void search(String query) {
    if (state is! SubGroupListSuccess) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    final current = state;
    if (current is! SubGroupListSuccess) return;
    await _subscribeToSubGroups(
      groupId: current.groupId,
      search: query.isEmpty ? null : query,
      limit: _pageSize,
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! SubGroupListSuccess || !current.hasNextPage || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    await _subscribeToSubGroups(
      groupId: current.groupId,
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
    if (current is! SubGroupListSuccess) return;
    _personCounts = await _fetchPersonCounts(current.groupId);
    await _subscribeToSubGroups(groupId: current.groupId, search: current.search, limit: current.limit);
  }

  /// Cancels any existing local subscription and resubscribes to
  /// `watchSubGroups(groupId: ..., search: search, limit: limit)`. Every
  /// emission also resolves `hasNextPage` via a one-shot `countSubGroups`
  /// call before building the next [SubGroupListSuccess], and merges the
  /// already-fetched [_personCounts] onto each row. Mirrors
  /// `CityListCubit._subscribeToCities`.
  Future<void> _subscribeToSubGroups({
    required int groupId,
    required String? search,
    required int limit,
    void Function(Object error)? onError,
  }) async {
    await _subGroupsSubscription?.cancel();
    final done = Completer<void>();

    void handleError(Object error) {
      if (onError != null) {
        onError(error);
      } else {
        emit(SubGroupListError(core.failureToMessage(const CacheFailure())));
      }
      if (!done.isCompleted) done.complete();
    }

    _subGroupsSubscription =
        _subGroupRepository.watchSubGroups(groupId: groupId, search: search, limit: limit).listen(
      (subGroups) async {
        try {
          final total = await _subGroupRepository.countSubGroups(groupId: groupId, search: search);
          final withCounts = subGroups
              .map((s) => s.copyWith(personCount: _personCounts[s.id] ?? s.personCount))
              .toList();
          emit(SubGroupListSuccess(
            subGroups: withCounts,
            groupId: groupId,
            search: search,
            limit: limit,
            hasNextPage: subGroups.length < total,
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
  /// locally. Reuses the existing nested `getSubGroups` endpoint (still
  /// group-scoped, unchanged this row) purely to read each row's count — a
  /// bounded single page is enough given Classification's expected low
  /// cardinality per group. A failure here is swallowed: the local stream
  /// still renders, just without fresh counts until the next load/refresh.
  Future<Map<int, int>> _fetchPersonCounts(int groupId) async {
    final result = await _subGroupRepository.getSubGroups(groupId: groupId, pageIndex: 1, pageSize: 200);
    return result.fold((_) => const {}, (page) => {for (final s in page.items) s.id: s.personCount});
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    _subGroupsSubscription?.cancel();
    return super.close();
  }
}
