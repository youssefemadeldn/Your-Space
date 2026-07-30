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

  const PeopleListSuccess({
    required this.people,
    required this.groups,
    this.selectedGroupId,
    this.search,
    required this.pageIndex,
    required this.hasNextPage,
    this.isLoadingMore = false,
  });

  PeopleListSuccess copyWith({
    List<Person>? people,
    int? pageIndex,
    bool? hasNextPage,
    bool? isLoadingMore,
  }) =>
      PeopleListSuccess(
        people: people ?? this.people,
        groups: groups,
        selectedGroupId: selectedGroupId,
        search: search,
        pageIndex: pageIndex ?? this.pageIndex,
        hasNextPage: hasNextPage ?? this.hasNextPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

  @override
  List<Object?> get props =>
      [people, groups, selectedGroupId, search, pageIndex, hasNextPage, isLoadingMore];
}

final class PeopleListError extends PeopleListState {
  final String message;
  const PeopleListError(this.message);
  @override
  List<Object?> get props => [message];
}
