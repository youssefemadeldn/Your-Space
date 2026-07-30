import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/entities/person.dart';

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
  final int pageIndex;
  final bool hasNextPage;
  final bool isLoadingMore;

  const ReciprocitySuggestionsSuccess({
    required this.suggestions,
    required this.groups,
    this.selectedGroupId,
    required this.pageIndex,
    required this.hasNextPage,
    this.isLoadingMore = false,
  });

  ReciprocitySuggestionsSuccess copyWith({
    List<Person>? suggestions,
    int? pageIndex,
    bool? hasNextPage,
    bool? isLoadingMore,
  }) =>
      ReciprocitySuggestionsSuccess(
        suggestions: suggestions ?? this.suggestions,
        groups: groups,
        selectedGroupId: selectedGroupId,
        pageIndex: pageIndex ?? this.pageIndex,
        hasNextPage: hasNextPage ?? this.hasNextPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

  @override
  List<Object?> get props =>
      [suggestions, groups, selectedGroupId, pageIndex, hasNextPage, isLoadingMore];
}

final class ReciprocitySuggestionsError extends ReciprocitySuggestionsState {
  final String message;
  const ReciprocitySuggestionsError(this.message);
  @override
  List<Object?> get props => [message];
}
