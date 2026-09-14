import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/entities/subgroup.dart';

sealed class SubGroupListState extends Equatable {
  const SubGroupListState();
  @override
  List<Object?> get props => const [];
}

final class SubGroupListInitial extends SubGroupListState {
  const SubGroupListInitial();
}

final class SubGroupListLoading extends SubGroupListState {
  const SubGroupListLoading();
}

final class SubGroupListSuccess extends SubGroupListState {
  final List<SubGroup> subGroups;
  final int groupId;
  final String? search;

  /// How many rows the local `watchSubGroups` query is currently asking for
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

  const SubGroupListSuccess({
    required this.subGroups,
    required this.groupId,
    this.search,
    required this.limit,
    required this.hasNextPage,
    this.isLoadingMore = false,
    this.loadMoreErrorMessage,
    this.loadMoreErrorId = 0,
  });

  SubGroupListSuccess copyWith({
    List<SubGroup>? subGroups,
    int? limit,
    bool? hasNextPage,
    bool? isLoadingMore,
    String? loadMoreErrorMessage,
    int? loadMoreErrorId,
  }) =>
      SubGroupListSuccess(
        subGroups: subGroups ?? this.subGroups,
        groupId: groupId,
        search: search,
        limit: limit ?? this.limit,
        hasNextPage: hasNextPage ?? this.hasNextPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreErrorMessage: loadMoreErrorMessage ?? this.loadMoreErrorMessage,
        loadMoreErrorId: loadMoreErrorId ?? this.loadMoreErrorId,
      );

  @override
  List<Object?> get props => [
        subGroups,
        groupId,
        search,
        limit,
        hasNextPage,
        isLoadingMore,
        loadMoreErrorMessage,
        loadMoreErrorId,
      ];
}

final class SubGroupListError extends SubGroupListState {
  final String message;
  const SubGroupListError(this.message);
  @override
  List<Object?> get props => [message];
}
