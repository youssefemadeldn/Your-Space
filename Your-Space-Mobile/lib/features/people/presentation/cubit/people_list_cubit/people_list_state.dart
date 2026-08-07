import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/entities/person.dart';

sealed class PeopleListState extends Equatable {
  const PeopleListState();
  @override
  List<Object?> get props => const [];
}

final class PeopleListInitial extends PeopleListState {
  const PeopleListInitial();
}

final class PeopleListLoading extends PeopleListState {
  const PeopleListLoading();
}

final class PeopleListSuccess extends PeopleListState {
  final List<Person> people;
  final List<Group> groups;
  final int? selectedGroupId;
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

  const PeopleListSuccess({
    required this.people,
    required this.groups,
    this.selectedGroupId,
    this.search,
    required this.pageIndex,
    required this.hasNextPage,
    this.isLoadingMore = false,
    this.loadMoreErrorMessage,
    this.loadMoreErrorId = 0,
  });

  PeopleListSuccess copyWith({
    List<Person>? people,
    List<Group>? groups,
    int? pageIndex,
    bool? hasNextPage,
    bool? isLoadingMore,
    String? loadMoreErrorMessage,
    int? loadMoreErrorId,
  }) =>
      PeopleListSuccess(
        people: people ?? this.people,
        groups: groups ?? this.groups,
        selectedGroupId: selectedGroupId,
        search: search,
        pageIndex: pageIndex ?? this.pageIndex,
        hasNextPage: hasNextPage ?? this.hasNextPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreErrorMessage: loadMoreErrorMessage ?? this.loadMoreErrorMessage,
        loadMoreErrorId: loadMoreErrorId ?? this.loadMoreErrorId,
      );

  @override
  List<Object?> get props => [
        people,
        groups,
        selectedGroupId,
        search,
        pageIndex,
        hasNextPage,
        isLoadingMore,
        loadMoreErrorMessage,
        loadMoreErrorId,
      ];
}

final class PeopleListError extends PeopleListState {
  final String message;
  const PeopleListError(this.message);
  @override
  List<Object?> get props => [message];
}
