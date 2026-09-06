import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/entities/neighborhood.dart';

sealed class NeighborhoodListState extends Equatable {
  const NeighborhoodListState();
  @override
  List<Object?> get props => const [];
}

final class NeighborhoodListInitial extends NeighborhoodListState {
  const NeighborhoodListInitial();
}

final class NeighborhoodListLoading extends NeighborhoodListState {
  const NeighborhoodListLoading();
}

final class NeighborhoodListSuccess extends NeighborhoodListState {
  final List<Neighborhood> neighborhoods;
  final int cityId;
  final String? search;
  final int pageIndex;
  final bool hasNextPage;
  final bool isLoadingMore;
  final String? loadMoreErrorMessage;
  final int loadMoreErrorId;

  const NeighborhoodListSuccess({
    required this.neighborhoods,
    required this.cityId,
    this.search,
    required this.pageIndex,
    required this.hasNextPage,
    this.isLoadingMore = false,
    this.loadMoreErrorMessage,
    this.loadMoreErrorId = 0,
  });

  NeighborhoodListSuccess copyWith({
    List<Neighborhood>? neighborhoods,
    int? pageIndex,
    bool? hasNextPage,
    bool? isLoadingMore,
    String? loadMoreErrorMessage,
    int? loadMoreErrorId,
  }) =>
      NeighborhoodListSuccess(
        neighborhoods: neighborhoods ?? this.neighborhoods,
        cityId: cityId,
        search: search,
        pageIndex: pageIndex ?? this.pageIndex,
        hasNextPage: hasNextPage ?? this.hasNextPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreErrorMessage: loadMoreErrorMessage ?? this.loadMoreErrorMessage,
        loadMoreErrorId: loadMoreErrorId ?? this.loadMoreErrorId,
      );

  @override
  List<Object?> get props => [
        neighborhoods,
        cityId,
        search,
        pageIndex,
        hasNextPage,
        isLoadingMore,
        loadMoreErrorMessage,
        loadMoreErrorId,
      ];
}

final class NeighborhoodListError extends NeighborhoodListState {
  final String message;
  const NeighborhoodListError(this.message);
  @override
  List<Object?> get props => [message];
}
