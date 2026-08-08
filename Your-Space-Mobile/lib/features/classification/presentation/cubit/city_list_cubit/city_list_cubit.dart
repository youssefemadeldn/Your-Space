import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/classification/domain/repositories/base_city_repository.dart';

import 'city_list_state.dart';

const _pageSize = 20;

@injectable
class CityListCubit extends Cubit<CityListState> {
  final CityRepository _cityRepository;
  final DataRefreshBus _dataRefreshBus;
  Timer? _searchDebounce;
  late final StreamSubscription<DataScope> _refreshSubscription;

  CityListCubit(this._cityRepository, this._dataRefreshBus) : super(const CityListInitial()) {
    _refreshSubscription = _dataRefreshBus.stream.listen((scope) {
      if (scope == DataScope.classification) refresh();
    });
  }

  Future<void> load(int governorateId) async {
    emit(const CityListLoading());
    final result =
        await _cityRepository.getCities(governorateId: governorateId, pageIndex: 1, pageSize: _pageSize);
    result.fold(
      (failure) => emit(CityListError(core.failureToMessage(failure))),
      (page) => emit(CityListSuccess(
        cities: page.items,
        governorateId: governorateId,
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
      )),
    );
  }

  void search(String query) {
    if (state is! CityListSuccess) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    final current = state;
    if (current is! CityListSuccess) return;
    final search = query.isEmpty ? null : query;
    final result = await _cityRepository.getCities(
      governorateId: current.governorateId,
      search: search,
      pageIndex: 1,
      pageSize: _pageSize,
    );
    result.fold(
      (failure) => emit(CityListError(core.failureToMessage(failure))),
      (page) => emit(CityListSuccess(
        cities: page.items,
        governorateId: current.governorateId,
        search: search,
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
      )),
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! CityListSuccess || !current.hasNextPage || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    final result = await _cityRepository.getCities(
      governorateId: current.governorateId,
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
        cities: [...current.cities, ...page.items],
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
        isLoadingMore: false,
      )),
    );
  }

  Future<void> refresh() async {
    final current = state;
    if (current is! CityListSuccess) return;
    final result = await _cityRepository.getCities(
      governorateId: current.governorateId,
      search: current.search,
      pageIndex: 1,
      pageSize: _pageSize,
    );
    result.fold(
      (_) {},
      (page) => emit(current.copyWith(cities: page.items, pageIndex: page.pageIndex, hasNextPage: page.hasNextPage)),
    );
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    _refreshSubscription.cancel();
    return super.close();
  }
}
