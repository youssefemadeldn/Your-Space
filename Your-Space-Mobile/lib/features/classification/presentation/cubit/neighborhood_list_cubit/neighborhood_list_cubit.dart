import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/classification/domain/repositories/base_neighborhood_repository.dart';

import 'neighborhood_list_state.dart';

const _pageSize = 20;

@injectable
class NeighborhoodListCubit extends Cubit<NeighborhoodListState> {
  final NeighborhoodRepository _neighborhoodRepository;
  final DataRefreshBus _dataRefreshBus;
  Timer? _searchDebounce;
  late final StreamSubscription<DataScope> _refreshSubscription;

  NeighborhoodListCubit(this._neighborhoodRepository, this._dataRefreshBus)
      : super(const NeighborhoodListInitial()) {
    _refreshSubscription = _dataRefreshBus.stream.listen((scope) {
      if (scope == DataScope.classification) refresh();
    });
  }

  Future<void> load(int cityId) async {
    emit(const NeighborhoodListLoading());
    final result =
        await _neighborhoodRepository.getNeighborhoods(cityId: cityId, pageIndex: 1, pageSize: _pageSize);
    result.fold(
      (failure) => emit(NeighborhoodListError(core.failureToMessage(failure))),
      (page) => emit(NeighborhoodListSuccess(
        neighborhoods: page.items,
        cityId: cityId,
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
      )),
    );
  }

  void search(String query) {
    if (state is! NeighborhoodListSuccess) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    final current = state;
    if (current is! NeighborhoodListSuccess) return;
    final search = query.isEmpty ? null : query;
    final result = await _neighborhoodRepository.getNeighborhoods(
      cityId: current.cityId,
      search: search,
      pageIndex: 1,
      pageSize: _pageSize,
    );
    result.fold(
      (failure) => emit(NeighborhoodListError(core.failureToMessage(failure))),
      (page) => emit(NeighborhoodListSuccess(
        neighborhoods: page.items,
        cityId: current.cityId,
        search: search,
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
      )),
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! NeighborhoodListSuccess || !current.hasNextPage || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    final result = await _neighborhoodRepository.getNeighborhoods(
      cityId: current.cityId,
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
        neighborhoods: [...current.neighborhoods, ...page.items],
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
        isLoadingMore: false,
      )),
    );
  }

  Future<void> refresh() async {
    final current = state;
    if (current is! NeighborhoodListSuccess) return;
    final result = await _neighborhoodRepository.getNeighborhoods(
      cityId: current.cityId,
      search: current.search,
      pageIndex: 1,
      pageSize: _pageSize,
    );
    result.fold(
      (_) {},
      (page) => emit(
          current.copyWith(neighborhoods: page.items, pageIndex: page.pageIndex, hasNextPage: page.hasNextPage)),
    );
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    _refreshSubscription.cancel();
    return super.close();
  }
}
