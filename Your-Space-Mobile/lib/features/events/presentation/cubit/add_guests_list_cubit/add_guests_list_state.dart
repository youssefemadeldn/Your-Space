import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/entities/city.dart';
import 'package:your_space_mobile/core/entities/governorate.dart';
import 'package:your_space_mobile/core/entities/neighborhood.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/entities/subgroup.dart';
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
///
/// [governorates] is a flat, always-loaded list (backs the "by governorate"
/// tab directly, and is the parent picker for the "by city"/"by neighborhood"
/// tabs). [subGroupOptions]/[cityOptions]/[neighborhoodOptions] are
/// on-demand — populated by [AddGuestsListCubit.loadSubGroupsForGroup] /
/// `loadCitiesForGovernorate` / `loadNeighborhoodsForCity` once a tab's own
/// local parent-picker state selects a parent; unlike [groupProgress] there's
/// no per-dimension "already added" progress endpoint, so these captions show
/// each entity's total `personCount`, not an available-to-add count.
final class AddGuestsListSuccess extends AddGuestsListState {
  final List<Person> availablePeople;
  final List<GroupGuestProgress> groupProgress;
  final List<Governorate> governorates;
  final List<SubGroup> subGroupOptions;
  final List<City> cityOptions;
  final List<Neighborhood> neighborhoodOptions;
  final int pageIndex;
  final bool hasNextPage;
  final bool isLoadingMore;

  const AddGuestsListSuccess({
    required this.availablePeople,
    required this.groupProgress,
    this.governorates = const [],
    this.subGroupOptions = const [],
    this.cityOptions = const [],
    this.neighborhoodOptions = const [],
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
    List<SubGroup>? subGroupOptions,
    List<City>? cityOptions,
    List<Neighborhood>? neighborhoodOptions,
    int? pageIndex,
    bool? hasNextPage,
    bool? isLoadingMore,
  }) =>
      AddGuestsListSuccess(
        availablePeople: availablePeople ?? this.availablePeople,
        groupProgress: groupProgress,
        governorates: governorates,
        subGroupOptions: subGroupOptions ?? this.subGroupOptions,
        cityOptions: cityOptions ?? this.cityOptions,
        neighborhoodOptions: neighborhoodOptions ?? this.neighborhoodOptions,
        pageIndex: pageIndex ?? this.pageIndex,
        hasNextPage: hasNextPage ?? this.hasNextPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

  @override
  List<Object?> get props => [
        availablePeople,
        groupProgress,
        governorates,
        subGroupOptions,
        cityOptions,
        neighborhoodOptions,
        pageIndex,
        hasNextPage,
        isLoadingMore,
      ];
}

final class AddGuestsListError extends AddGuestsListState {
  final String message;
  const AddGuestsListError(this.message);
  @override
  List<Object?> get props => [message];
}
