import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/entities/city.dart';

sealed class CityListState extends Equatable {
  const CityListState();
  @override
  List<Object?> get props => const [];
}

final class CityListInitial extends CityListState {
  const CityListInitial();
}

final class CityListLoading extends CityListState {
  const CityListLoading();
}

final class CityListSuccess extends CityListState {
  final List<City> cities;
  final int governorateId;
  final String? search;
  final int pageIndex;
  final bool hasNextPage;
  final bool isLoadingMore;
  final String? loadMoreErrorMessage;
  final int loadMoreErrorId;

  const CityListSuccess({
    required this.cities,
    required this.governorateId,
    this.search,
    required this.pageIndex,
    required this.hasNextPage,
    this.isLoadingMore = false,
    this.loadMoreErrorMessage,
    this.loadMoreErrorId = 0,
  });

  CityListSuccess copyWith({
    List<City>? cities,
    int? pageIndex,
    bool? hasNextPage,
    bool? isLoadingMore,
    String? loadMoreErrorMessage,
    int? loadMoreErrorId,
  }) =>
      CityListSuccess(
        cities: cities ?? this.cities,
        governorateId: governorateId,
        search: search,
        pageIndex: pageIndex ?? this.pageIndex,
        hasNextPage: hasNextPage ?? this.hasNextPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreErrorMessage: loadMoreErrorMessage ?? this.loadMoreErrorMessage,
        loadMoreErrorId: loadMoreErrorId ?? this.loadMoreErrorId,
      );

  @override
  List<Object?> get props =>
      [cities, governorateId, search, pageIndex, hasNextPage, isLoadingMore, loadMoreErrorMessage, loadMoreErrorId];
}

final class CityListError extends CityListState {
  final String message;
  const CityListError(this.message);
  @override
  List<Object?> get props => [message];
}
