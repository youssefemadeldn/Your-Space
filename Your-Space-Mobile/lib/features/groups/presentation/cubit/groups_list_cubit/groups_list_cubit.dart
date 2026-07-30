import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';

import 'groups_list_state.dart';

const _pageSize = 20;

@injectable
class GroupsListCubit extends Cubit<GroupsListState> {
  final GroupRepository _groupRepository;
  Timer? _searchDebounce;

  GroupsListCubit(this._groupRepository) : super(const GroupsListInitial());

  Future<void> load() async {
    emit(const GroupsListLoading());
    final result = await _groupRepository.getGroups(pageIndex: 1, pageSize: _pageSize);
    result.fold(
      (failure) => emit(GroupsListError(core.failureToMessage(failure))),
      (page) => emit(GroupsListSuccess(page.items, pageIndex: page.pageIndex, hasNextPage: page.hasNextPage)),
    );
  }

  /// Debounced — this is bound directly to every keystroke in the search
  /// field, and a real network call per keystroke would spam the backend.
  void search(String query) {
    if (state is! GroupsListSuccess) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    final search = query.isEmpty ? null : query;
    final result = await _groupRepository.getGroups(search: search, pageIndex: 1, pageSize: _pageSize);
    result.fold(
      (failure) => emit(GroupsListError(core.failureToMessage(failure))),
      (page) => emit(GroupsListSuccess(
        page.items,
        search: search,
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
      )),
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! GroupsListSuccess || !current.hasNextPage || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    final result = await _groupRepository.getGroups(
      search: current.search,
      pageIndex: current.pageIndex + 1,
      pageSize: _pageSize,
    );
    result.fold(
      (failure) => emit(current.copyWith(isLoadingMore: false)),
      (page) => emit(current.copyWith(
        groups: [...current.groups, ...page.items],
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
        isLoadingMore: false,
      )),
    );
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
