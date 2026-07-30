import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/features/events/domain/entities/group_guest_progress.dart';

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

/// [availablePeople] excludes persons already on this event's guest list —
/// the checklist should never let the user redundantly re-select them. Only
/// correctly excludes the event's first 50 already-added guests (see cubit
/// doc comment) — an accepted personal-scale approximation.
///
/// [groupProgress] backs the "by group" tab's per-group availability count
/// (`totalPersonsInGroup - guestsAddedCount`) — sourced from the same
/// `/progress` endpoint `EventDetailsCubit` uses, which is accurate
/// regardless of how much of [availablePeople] has been scroll-paginated in.
final class AddGuestsListSuccess extends AddGuestsListState {
  final List<Person> availablePeople;
  final List<GroupGuestProgress> groupProgress;
  final int pageIndex;
  final bool hasNextPage;
  final bool isLoadingMore;

  const AddGuestsListSuccess({
    required this.availablePeople,
    required this.groupProgress,
    required this.pageIndex,
    required this.hasNextPage,
    this.isLoadingMore = false,
  });

  int availableCountForGroup(int groupId) {
    for (final progress in groupProgress) {
      if (progress.groupId == groupId) return progress.totalPersonsInGroup - progress.guestsAddedCount;
    }
    return 0;
  }

  AddGuestsListSuccess copyWith({
    List<Person>? availablePeople,
    int? pageIndex,
    bool? hasNextPage,
    bool? isLoadingMore,
  }) =>
      AddGuestsListSuccess(
        availablePeople: availablePeople ?? this.availablePeople,
        groupProgress: groupProgress,
        pageIndex: pageIndex ?? this.pageIndex,
        hasNextPage: hasNextPage ?? this.hasNextPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

  @override
  List<Object?> get props => [availablePeople, groupProgress, pageIndex, hasNextPage, isLoadingMore];
}

final class AddGuestsListError extends AddGuestsListState {
  final String message;
  const AddGuestsListError(this.message);
  @override
  List<Object?> get props => [message];
}
