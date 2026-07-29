import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/mock/entities/group.dart';

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
  const GroupsListSuccess(this.groups);
  @override
  List<Object?> get props => [groups];
}

final class GroupsListError extends GroupsListState {
  final String message;
  const GroupsListError(this.message);
  @override
  List<Object?> get props => [message];
}
