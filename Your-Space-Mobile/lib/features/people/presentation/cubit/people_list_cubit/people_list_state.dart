import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/entities/city.dart';
import 'package:your_space_mobile/core/entities/governorate.dart';
import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/entities/neighborhood.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/entities/subgroup.dart';

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

  /// Options for the subgroup chip row — only populated once [selectedGroupId]
  /// is set (a subgroup is meaningless without a parent group).
  final List<SubGroup> subGroups;
  final int? selectedSubGroupId;

  final List<Governorate> governorates;
  final int? selectedGovernorateId;

  /// Options for the City picker — only populated once [selectedGovernorateId]
  /// is set.
  final List<City> cities;
  final int? selectedCityId;

  /// Options for the Neighborhood picker — only populated once [selectedCityId]
  /// is set.
  final List<Neighborhood> neighborhoods;
  final int? selectedNeighborhoodId;

  final String? search;
  final int pageIndex;
  final bool hasNextPage;
  final bool isLoadingMore;

  /// One-shot signal for a failed `loadMore()`. [loadMoreErrorId] increments
  /// on every failure so a screen listener can fire exactly once per failure
  /// (via `listenWhen` comparing the id) without needing to clear
  /// [loadMoreErrorMessage] back to null afterward — nullable fields can't be
  /// reset through a standard `?? this.field` copyWith anyway.
  final String? loadMoreErrorMessage;
  final int loadMoreErrorId;

  const PeopleListSuccess({
    required this.people,
    required this.groups,
    this.selectedGroupId,
    this.subGroups = const [],
    this.selectedSubGroupId,
    this.governorates = const [],
    this.selectedGovernorateId,
    this.cities = const [],
    this.selectedCityId,
    this.neighborhoods = const [],
    this.selectedNeighborhoodId,
    this.search,
    required this.pageIndex,
    required this.hasNextPage,
    this.isLoadingMore = false,
    this.loadMoreErrorMessage,
    this.loadMoreErrorId = 0,
  });

  bool get hasActiveFilters =>
      selectedGroupId != null ||
      selectedSubGroupId != null ||
      selectedGovernorateId != null ||
      selectedCityId != null ||
      selectedNeighborhoodId != null;

  /// Preserves every selection field verbatim — only for updates that never
  /// change *which* filters are active (pagination, background refreshes,
  /// option-list refreshes). Anything that changes a selected id builds a
  /// fresh [PeopleListSuccess] directly instead (see `PeopleListCubit._refetch`).
  PeopleListSuccess copyWith({
    List<Person>? people,
    List<Group>? groups,
    List<SubGroup>? subGroups,
    List<Governorate>? governorates,
    List<City>? cities,
    List<Neighborhood>? neighborhoods,
    int? pageIndex,
    bool? hasNextPage,
    bool? isLoadingMore,
    String? loadMoreErrorMessage,
    int? loadMoreErrorId,
  }) =>
      PeopleListSuccess(
        people: people ?? this.people,
        groups: groups ?? this.groups,
        selectedGroupId: selectedGroupId,
        subGroups: subGroups ?? this.subGroups,
        selectedSubGroupId: selectedSubGroupId,
        governorates: governorates ?? this.governorates,
        selectedGovernorateId: selectedGovernorateId,
        cities: cities ?? this.cities,
        selectedCityId: selectedCityId,
        neighborhoods: neighborhoods ?? this.neighborhoods,
        selectedNeighborhoodId: selectedNeighborhoodId,
        search: search,
        pageIndex: pageIndex ?? this.pageIndex,
        hasNextPage: hasNextPage ?? this.hasNextPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreErrorMessage: loadMoreErrorMessage ?? this.loadMoreErrorMessage,
        loadMoreErrorId: loadMoreErrorId ?? this.loadMoreErrorId,
      );

  @override
  List<Object?> get props => [
        people,
        groups,
        selectedGroupId,
        subGroups,
        selectedSubGroupId,
        governorates,
        selectedGovernorateId,
        cities,
        selectedCityId,
        neighborhoods,
        selectedNeighborhoodId,
        search,
        pageIndex,
        hasNextPage,
        isLoadingMore,
        loadMoreErrorMessage,
        loadMoreErrorId,
      ];
}

final class PeopleListError extends PeopleListState {
  final String message;
  const PeopleListError(this.message);
  @override
  List<Object?> get props => [message];
}
