import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/classification/domain/repositories/base_subgroup_repository.dart';

import 'subgroup_list_state.dart';

const _pageSize = 20;

@injectable
class SubGroupListCubit extends Cubit<SubGroupListState> {
  final SubGroupRepository _subGroupRepository;
  final DataRefreshBus _dataRefreshBus;
  Timer? _searchDebounce;
  late final StreamSubscription<DataScope> _refreshSubscription;

  SubGroupListCubit(this._subGroupRepository, this._dataRefreshBus) : super(const SubGroupListInitial()) {
    _refreshSubscription = _dataRefreshBus.stream.listen((scope) {
      if (scope == DataScope.classification) refresh();
    });
  }

  Future<void> load(int groupId) async {
    emit(const SubGroupListLoading());
    final result =
        await _subGroupRepository.getSubGroups(groupId: groupId, pageIndex: 1, pageSize: _pageSize);
    result.fold(
      (failure) => emit(SubGroupListError(core.failureToMessage(failure))),
      (page) => emit(SubGroupListSuccess(
        subGroups: page.items,
        groupId: groupId,
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
      )),
    );
  }

  void search(String query) {
    if (state is! SubGroupListSuccess) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    final current = state;
    if (current is! SubGroupListSuccess) return;
    final search = query.isEmpty ? null : query;
    final result = await _subGroupRepository.getSubGroups(
      groupId: current.groupId,
      search: search,
      pageIndex: 1,
      pageSize: _pageSize,
    );
    result.fold(
      (failure) => emit(SubGroupListError(core.failureToMessage(failure))),
      (page) => emit(SubGroupListSuccess(
        subGroups: page.items,
        groupId: current.groupId,
        search: search,
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
      )),
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! SubGroupListSuccess || !current.hasNextPage || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    final result = await _subGroupRepository.getSubGroups(
      groupId: current.groupId,
      search: current.search,
      pageIndex: current.pageIndex + 1,
      pageSize: _pageSize,
    );
    result.fold(
      (failure) => emit(current.copyWith(
        isLoadingMore: false,
        loadMoreErrorMessage: core.failureToMessage(failure),
        loadMoreErrorId: current.loadMoreErrorId + 1,
      )),
      (page) => emit(current.copyWith(
        subGroups: [...current.subGroups, ...page.items],
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
        isLoadingMore: false,
      )),
    );
  }

  /// Re-fetches page 1 — triggered by [DataRefreshBus] on a `classification`
  /// scope notification (e.g. this same screen's own action cubit, or the
  /// wizard's inline "+ Add new" elsewhere) and by pull-to-refresh.
  Future<void> refresh() async {
    final current = state;
    if (current is! SubGroupListSuccess) return;
    final result = await _subGroupRepository.getSubGroups(
      groupId: current.groupId,
      search: current.search,
      pageIndex: 1,
      pageSize: _pageSize,
    );
    result.fold(
      (_) {},
      (page) =>
          emit(current.copyWith(subGroups: page.items, pageIndex: page.pageIndex, hasNextPage: page.hasNextPage)),
    );
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    _refreshSubscription.cancel();
    return super.close();
  }
}
