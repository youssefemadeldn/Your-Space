import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/features/people/domain/entities/person_occasion_history_entry.dart';

sealed class PersonDetailsState extends Equatable {
  const PersonDetailsState();
  @override
  List<Object?> get props => const [];
}

final class PersonDetailsInitial extends PersonDetailsState {
  const PersonDetailsInitial();
}

final class PersonDetailsLoading extends PersonDetailsState {
  const PersonDetailsLoading();
}

final class PersonDetailsSuccess extends PersonDetailsState {
  final Person person;
  final List<PersonOccasionHistoryEntry> occasions;

  const PersonDetailsSuccess({required this.person, required this.occasions});

  @override
  List<Object?> get props => [person, occasions];
}

final class PersonDetailsError extends PersonDetailsState {
  final String message;
  const PersonDetailsError(this.message);
  @override
  List<Object?> get props => [message];
}
