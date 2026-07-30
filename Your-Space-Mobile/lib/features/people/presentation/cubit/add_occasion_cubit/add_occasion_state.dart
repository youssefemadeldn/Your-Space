import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/features/people/domain/entities/person_occasion_history_entry.dart';

sealed class AddOccasionState extends Equatable {
  const AddOccasionState();
  @override
  List<Object?> get props => const [];
}

final class AddOccasionInitial extends AddOccasionState {
  const AddOccasionInitial();
}

final class AddOccasionSubmitting extends AddOccasionState {
  const AddOccasionSubmitting();
}

final class AddOccasionSuccess extends AddOccasionState {
  final PersonOccasionHistoryEntry entry;
  const AddOccasionSuccess(this.entry);
  @override
  List<Object?> get props => [entry];
}

final class AddOccasionError extends AddOccasionState {
  final String message;
  const AddOccasionError(this.message);
  @override
  List<Object?> get props => [message];
}
