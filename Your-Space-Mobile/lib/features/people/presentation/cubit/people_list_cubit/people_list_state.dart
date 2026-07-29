import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/mock/entities/group.dart';
import 'package:your_space_mobile/core/mock/entities/person.dart';

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

  const PeopleListSuccess({
    required this.people,
    required this.groups,
    this.selectedGroupId,
  });

  @override
  List<Object?> get props => [people, groups, selectedGroupId];
}

final class PeopleListError extends PeopleListState {
  final String message;
  const PeopleListError(this.message);
  @override
  List<Object?> get props => [message];
}
