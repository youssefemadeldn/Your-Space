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

  const GroupsListSuccess(
    this.groups, {
    this.search,
    required this.pageIndex,
    required this.hasNextPage,
    this.isLoadingMore = false,
  });

  GroupsListSuccess copyWith({
    List<Group>? groups,
    int? pageIndex,
    bool? hasNextPage,
    bool? isLoadingMore,
  }) =>
      GroupsListSuccess(
        groups ?? this.groups,
        search: search,
        pageIndex: pageIndex ?? this.pageIndex,
        hasNextPage: hasNextPage ?? this.hasNextPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

  @override
  List<Object?> get props => [groups, search, pageIndex, hasNextPage, isLoadingMore];
}

final class GroupsListError extends GroupsListState {
  final String message;
  const GroupsListError(this.message);
  @override
  List<Object?> get props => [message];
}
