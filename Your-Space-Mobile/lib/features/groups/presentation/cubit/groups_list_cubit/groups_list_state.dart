import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/entities/group.dart';

sealed class GroupsListState extends Equatable {
  const GroupsListState();
  @override
  List<Object?> get props => const [];
}

final class GroupsListInitial extends GroupsListState {
  const GroupsListInitial();
}

final class GroupsListLoading extends GroupsListState {
  const GroupsListLoading();
}

final class GroupsListSuccess extends GroupsListState {
  final List<Group> groups;
  final String? search;
  final int pageIndex;
  final bool hasNextPage;
  final bool isLoadingMore;

  /// One-shot signal for a failed `loadMore()`. [loadMoreErrorId] increments
  /// on every failure so a screen listener can fire exactly once per failure
  /// (via `listenWhen` comparing the id) without needing to clear
  /// [loadMoreErrorMessage] back to null afterward — nullable fields can't be
  /// reset through a standard `?? this.field` copyWith anyway.
  final String? loadMoreErrorMessage;
  final int loadMoreErrorId;

  const GroupsListSuccess(
    this.groups, {
    this.search,
    required this.pageIndex,
    required this.hasNextPage,
    this.isLoadingMore = false,
    this.loadMoreErrorMessage,
    this.loadMoreErrorId = 0,
  });

  GroupsListSuccess copyWith({
    List<Group>? groups,
    int? pageIndex,
    bool? hasNextPage,
    bool? isLoadingMore,
    String? loadMoreErrorMessage,
    int? loadMoreErrorId,
  }) =>
      GroupsListSuccess(
        groups ?? this.groups,
        search: search,
        pageIndex: pageIndex ?? this.pageIndex,
        hasNextPage: hasNextPage ?? this.hasNextPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreErrorMessage: loadMoreErrorMessage ?? this.loadMoreErrorMessage,
        loadMoreErrorId: loadMoreErrorId ?? this.loadMoreErrorId,
      );

  @override
  List<Object?> get props =>
      [groups, search, pageIndex, hasNextPage, isLoadingMore, loadMoreErrorMessage, loadMoreErrorId];
}

final class GroupsListError extends GroupsListState {
  final String message;
  const GroupsListError(this.message);
  @override
  List<Object?> get props => [message];
}
