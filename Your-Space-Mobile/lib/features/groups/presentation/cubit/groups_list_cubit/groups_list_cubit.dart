import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';

import 'groups_list_state.dart';

const _pageSize = 20;

/// Groups is local-first (CLAUDE.md Architecture rule 7, row 7.2): the list
/// is read from a reactive drift `Stream` via `watchGroups()` — mirrors
/// `PeopleListCubit`'s `_subscribeToPersons` pattern, simplified since Groups
/// has no filter dimensions, only search. No `DataRefreshBus` subscription is
/// needed here anymore: `GroupRepositoryImpl.createGroup`/`updateGroup`
/// already upsert into drift on success, so every open `watchGroups` stream
/// (including the wizard's inline "+ Add new group") sees the change
/// directly (design doc §7), the same reasoning `PeopleListCubit` documents
/// for its now-empty `DataScope.people` case.
@injectable
class GroupsListCubit extends Cubit<GroupsListState> {
  final GroupRepository _groupRepository;
  Timer? _searchDebounce;
  StreamSubscription<List<Group>>? _groupsSubscription;

  GroupsListCubit(this._groupRepository) : super(const GroupsListInitial());

  Future<void> load() async {
    emit(const GroupsListLoading());
    await _subscribeToGroups(search: null, limit: _pageSize);
  }

  /// Debounced — this is bound directly to every keystroke in the search
  /// field, and a query per keystroke would thrash the local read.
  void search(String query) {
    if (state is! GroupsListSuccess) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    if (state is! GroupsListSuccess) return;
    await _subscribeToGroups(search: query.isEmpty ? null : query, limit: _pageSize);
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! GroupsListSuccess || !current.hasNextPage || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    await _subscribeToGroups(
      search: current.search,
      limit: current.limit + _pageSize,
      onError: (_) => emit(current.copyWith(
        isLoadingMore: false,
        loadMoreErrorMessage: core.failureToMessage(const CacheFailure()),
        loadMoreErrorId: current.loadMoreErrorId + 1,
      )),
    );
  }

  /// No-op beyond re-subscribing: the drift `Stream` already re-emits on
  /// upsert/tombstone, so pull-to-refresh has nothing to fetch from the
  /// network here (Groups has no Tier 3 pull wired up until row 7.4).
  Future<void> refresh() async {
    final current = state;
    if (current is! GroupsListSuccess) return;
    await _subscribeToGroups(search: current.search, limit: current.limit);
  }

  /// Cancels any existing local subscription and resubscribes to
  /// `watchGroups(search: search, limit: limit)`. Every emission also
  /// resolves `hasNextPage` via a one-shot `countGroups` call before building
  /// the next [GroupsListSuccess]. The single path every search mutator and
  /// `loadMore()` funnels through — mirrors `PeopleListCubit._subscribeToPersons`.
  ///
  /// [onError] lets `loadMore()` report a failure through its own
  /// `loadMoreErrorMessage`/`loadMoreErrorId` retry-snackbar path instead of
  /// the default: replacing the whole screen with [GroupsListError].
  Future<void> _subscribeToGroups({
    required String? search,
    required int limit,
    void Function(Object error)? onError,
  }) async {
    await _groupsSubscription?.cancel();
    final done = Completer<void>();

    void handleError(Object error) {
      if (onError != null) {
        onError(error);
      } else {
        emit(GroupsListError(core.failureToMessage(const CacheFailure())));
      }
      if (!done.isCompleted) done.complete();
    }

    _groupsSubscription = _groupRepository.watchGroups(search: search, limit: limit).listen(
      (groups) async {
        try {
          final total = await _groupRepository.countGroups(search: search);
          emit(GroupsListSuccess(groups, search: search, limit: limit, hasNextPage: groups.length < total));
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
    _groupsSubscription?.cancel();
    return super.close();
  }
}
