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

  /// How many rows the local `watchNeighborhoods` query is currently asking
  /// for (grows by the page size on `loadMore()`) — a local read window, not
  /// a server page index (Tier 1, design doc §3).
  final int limit;
  final bool hasNextPage;
  final bool isLoadingMore;

  /// One-shot signal for a failed `loadMore()`. [loadMoreErrorId] increments
  /// on every failure so a screen listener can fire exactly once per failure
  /// (via `listenWhen` comparing the id) without needing to clear
  /// [loadMoreErrorMessage] back to null afterward — nullable fields can't be
  /// reset through a standard `?? this.field` copyWith anyway.
  final String? loadMoreErrorMessage;
  final int loadMoreErrorId;

  const NeighborhoodListSuccess({
    required this.neighborhoods,
    required this.cityId,
    this.search,
    required this.limit,
    required this.hasNextPage,
    this.isLoadingMore = false,
    this.loadMoreErrorMessage,
    this.loadMoreErrorId = 0,
  });

  NeighborhoodListSuccess copyWith({
    List<Neighborhood>? neighborhoods,
    int? limit,
    bool? hasNextPage,
    bool? isLoadingMore,
    String? loadMoreErrorMessage,
    int? loadMoreErrorId,
  }) =>
      NeighborhoodListSuccess(
        neighborhoods: neighborhoods ?? this.neighborhoods,
        cityId: cityId,
        search: search,
        limit: limit ?? this.limit,
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
        limit,
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
