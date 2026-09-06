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
  final int pageIndex;
  final bool hasNextPage;
  final bool isLoadingMore;
  final String? loadMoreErrorMessage;
  final int loadMoreErrorId;

  const SubGroupListSuccess({
    required this.subGroups,
    required this.groupId,
    this.search,
    required this.pageIndex,
    required this.hasNextPage,
    this.isLoadingMore = false,
    this.loadMoreErrorMessage,
    this.loadMoreErrorId = 0,
  });

  SubGroupListSuccess copyWith({
    List<SubGroup>? subGroups,
    int? pageIndex,
    bool? hasNextPage,
    bool? isLoadingMore,
    String? loadMoreErrorMessage,
    int? loadMoreErrorId,
  }) =>
      SubGroupListSuccess(
        subGroups: subGroups ?? this.subGroups,
        groupId: groupId,
        search: search,
        pageIndex: pageIndex ?? this.pageIndex,
        hasNextPage: hasNextPage ?? this.hasNextPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreErrorMessage: loadMoreErrorMessage ?? this.loadMoreErrorMessage,
        loadMoreErrorId: loadMoreErrorId ?? this.loadMoreErrorId,
      );

  @override
  List<Object?> get props =>
      [subGroups, groupId, search, pageIndex, hasNextPage, isLoadingMore, loadMoreErrorMessage, loadMoreErrorId];
}

final class SubGroupListError extends SubGroupListState {
  final String message;
  const SubGroupListError(this.message);
  @override
  List<Object?> get props => [message];
}
