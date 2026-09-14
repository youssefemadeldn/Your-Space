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

  /// How many rows the local `watchCities` query is currently asking for
  /// (grows by the page size on `loadMore()`) — a local read window, not a
  /// server page index (Tier 1, design doc §3).
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

  const CityListSuccess({
    required this.cities,
    required this.governorateId,
    this.search,
    required this.limit,
    required this.hasNextPage,
    this.isLoadingMore = false,
    this.loadMoreErrorMessage,
    this.loadMoreErrorId = 0,
  });

  CityListSuccess copyWith({
    List<City>? cities,
    int? limit,
    bool? hasNextPage,
    bool? isLoadingMore,
    String? loadMoreErrorMessage,
    int? loadMoreErrorId,
  }) =>
      CityListSuccess(
        cities: cities ?? this.cities,
        governorateId: governorateId,
        search: search,
        limit: limit ?? this.limit,
        hasNextPage: hasNextPage ?? this.hasNextPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreErrorMessage: loadMoreErrorMessage ?? this.loadMoreErrorMessage,
        loadMoreErrorId: loadMoreErrorId ?? this.loadMoreErrorId,
      );

  @override
  List<Object?> get props => [
        cities,
        governorateId,
        search,
        limit,
        hasNextPage,
        isLoadingMore,
        loadMoreErrorMessage,
        loadMoreErrorId,
      ];
}

final class CityListError extends CityListState {
  final String message;
  const CityListError(this.message);
  @override
  List<Object?> get props => [message];
}
