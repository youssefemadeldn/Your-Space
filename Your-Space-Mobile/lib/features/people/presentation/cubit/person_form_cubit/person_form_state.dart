import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/mock/entities/group.dart';
import 'package:your_space_mobile/core/mock/entities/person.dart';

sealed class PersonFormState extends Equatable {
  const PersonFormState();
  @override
  List<Object?> get props => const [];
}

final class PersonFormInitial extends PersonFormState {
  const PersonFormInitial();
}

/// [person] is null in create mode, populated in edit mode for pre-fill.
final class PersonFormReady extends PersonFormState {
  final Person? person;
  final List<Group> availableGroups;

  const PersonFormReady({this.person, required this.availableGroups});

  @override
  List<Object?> get props => [person, availableGroups];
}

final class PersonFormSubmitting extends PersonFormState {
  const PersonFormSubmitting();
}

final class PersonFormSuccess extends PersonFormState {
  final Person person;
  const PersonFormSuccess(this.person);
  @override
  List<Object?> get props => [person];
}

final class PersonFormError extends PersonFormState {
  final String message;
  const PersonFormError(this.message);
  @override
  List<Object?> get props => [message];
}
