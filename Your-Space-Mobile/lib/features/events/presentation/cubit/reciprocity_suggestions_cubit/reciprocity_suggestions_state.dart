import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/mock/entities/group.dart';
import 'package:your_space_mobile/core/mock/entities/person.dart';

sealed class ReciprocitySuggestionsState extends Equatable {
  const ReciprocitySuggestionsState();
  @override
  List<Object?> get props => const [];
}

final class ReciprocitySuggestionsInitial extends ReciprocitySuggestionsState {
  const ReciprocitySuggestionsInitial();
}

final class ReciprocitySuggestionsLoading extends ReciprocitySuggestionsState {
  const ReciprocitySuggestionsLoading();
}

final class ReciprocitySuggestionsSuccess extends ReciprocitySuggestionsState {
  final List<Person> suggestions;
  final List<Group> groups;
  final int? selectedGroupId;

  const ReciprocitySuggestionsSuccess({
    required this.suggestions,
    required this.groups,
    this.selectedGroupId,
  });

  @override
  List<Object?> get props => [suggestions, groups, selectedGroupId];
}

final class ReciprocitySuggestionsError extends ReciprocitySuggestionsState {
  final String message;
  const ReciprocitySuggestionsError(this.message);
  @override
  List<Object?> get props => [message];
}
