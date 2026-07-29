import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/mock/entities/group.dart';
import 'package:your_space_mobile/core/mock/entities/person.dart';

sealed class AddGuestsListState extends Equatable {
  const AddGuestsListState();
  @override
  List<Object?> get props => const [];
}

final class AddGuestsListInitial extends AddGuestsListState {
  const AddGuestsListInitial();
}

final class AddGuestsListLoading extends AddGuestsListState {
  const AddGuestsListLoading();
}

/// [availablePeople] already excludes persons already on this event's guest
/// list — the checklist should never let the user redundantly re-select them.
final class AddGuestsListSuccess extends AddGuestsListState {
  final List<Person> availablePeople;
  final List<Group> groups;

  const AddGuestsListSuccess({required this.availablePeople, required this.groups});

  int availableCountForGroup(int groupId) =>
      availablePeople.where((p) => p.groupId == groupId).length;

  @override
  List<Object?> get props => [availablePeople, groups];
}

final class AddGuestsListError extends AddGuestsListState {
  final String message;
  const AddGuestsListError(this.message);
  @override
  List<Object?> get props => [message];
}
