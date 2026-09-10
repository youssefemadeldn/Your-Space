import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/city.dart';
import 'package:your_space_mobile/core/entities/governorate.dart';
import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/entities/neighborhood.dart';
import 'package:your_space_mobile/core/entities/subgroup.dart';
import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/classification/domain/repositories/base_city_repository.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_governorate_repository.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_neighborhood_repository.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_subgroup_repository.dart';
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';

import 'people_list_state.dart';

const _pageSize = 20;
const _refPageSize = 50;

/// Wide constructor is inherent, not a smell — this cubit is the People
/// screen's single source of truth for 5 filter dimensions (group, subgroup,
/// governorate, city, neighborhood), each backed by its own small reference
/// repository. Mirrors `PersonWizardCubit`'s equivalent orchestration.
@injectable
class PeopleListCubit extends Cubit<PeopleListState> {
  final PersonRepository _personRepository;
  final GroupRepository _groupRepository;
  final SubGroupRepository _subGroupRepository;
  final GovernorateRepository _governorateRepository;
  final CityRepository _cityRepository;
  final NeighborhoodRepository _neighborhoodRepository;
  final DataRefreshBus _dataRefreshBus;
  Timer? _searchDebounce;
  late final StreamSubscription<DataScope> _refreshSubscription;

  PeopleListCubit(
    this._personRepository,
    this._groupRepository,
    this._subGroupRepository,
    this._governorateRepository,
    this._cityRepository,
    this._neighborhoodRepository,
    this._dataRefreshBus,
  ) : super(const PeopleListInitial()) {
    _refreshSubscription = _dataRefreshBus.stream.listen((scope) {
      switch (scope) {
        case DataScope.people:
          refresh();
        case DataScope.groups:
          refreshGroups();
        case DataScope.classification:
          // A Subgroup/Governorate/City/Neighborhood was created (e.g. via the
          // wizard's inline "+ Add new") elsewhere — refresh whatever filter
          // option lists this cubit is currently holding.
          refreshClassificationFilters();
        case DataScope.events:
        case DataScope.eventGuests:
        case DataScope.profile:
          break;
      }
    });
  }

  Future<void> load() async {
    emit(const PeopleListLoading());
    final groupsResult = await _groupRepository.getGroups(pageIndex: 1, pageSize: _refPageSize);
    final groups = groupsResult.fold((_) => const <Group>[], (page) => page.items);
    final governoratesResult = await _governorateRepository.getGovernorates(pageIndex: 1, pageSize: _refPageSize);
    final governorates = governoratesResult.fold((_) => const <Governorate>[], (page) => page.items);
    final peopleResult = await _personRepository.getPersons(pageIndex: 1, pageSize: _pageSize);
    peopleResult.fold(
      (failure) => emit(PeopleListError(core.failureToMessage(failure))),
      (page) => emit(PeopleListSuccess(
        people: page.items,
        groups: groups,
        governorates: governorates,
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
      )),
    );
  }

  /// Debounced — bound directly to every keystroke in the search field.
  void search(String query) {
    if (state is! PeopleListSuccess) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    final current = state;
    if (current is! PeopleListSuccess) return;
    await _refetch(
      current,
      groupId: current.selectedGroupId,
      subGroupId: current.selectedSubGroupId,
      governorateId: current.selectedGovernorateId,
      cityId: current.selectedCityId,
      neighborhoodId: current.selectedNeighborhoodId,
      search: query.isEmpty ? null : query,
    );
  }

  Future<void> filterByGroup(int? groupId) async {
    final current = state;
    if (current is! PeopleListSuccess) return;
    var subGroups = const <SubGroup>[];
    if (groupId != null) {
      final result = await _subGroupRepository.getSubGroups(groupId: groupId, pageIndex: 1, pageSize: _refPageSize);
      subGroups = result.fold((_) => const <SubGroup>[], (p) => p.items);
    }
    await _refetch(
      current,
      groupId: groupId,
      subGroupId: null, // a subgroup belongs to the previous group — reset
      governorateId: current.selectedGovernorateId,
      cityId: current.selectedCityId,
      neighborhoodId: current.selectedNeighborhoodId,
      search: current.search,
      subGroups: subGroups,
    );
  }

  Future<void> filterBySubGroup(int? subGroupId) async {
    final current = state;
    if (current is! PeopleListSuccess) return;
    await _refetch(
      current,
      groupId: current.selectedGroupId,
      subGroupId: subGroupId,
      governorateId: current.selectedGovernorateId,
      cityId: current.selectedCityId,
      neighborhoodId: current.selectedNeighborhoodId,
      search: current.search,
    );
  }

  Future<void> filterByGovernorate(int? governorateId) async {
    final current = state;
    if (current is! PeopleListSuccess) return;
    var cities = const <City>[];
    if (governorateId != null) {
      final result =
          await _cityRepository.getCities(governorateId: governorateId, pageIndex: 1, pageSize: _refPageSize);
      cities = result.fold((_) => const <City>[], (p) => p.items);
    }
    await _refetch(
      current,
      groupId: current.selectedGroupId,
      subGroupId: current.selectedSubGroupId,
      governorateId: governorateId,
      cityId: null, // a city belongs to the previous governorate — reset
      neighborhoodId: null,
      search: current.search,
      cities: cities,
      neighborhoods: const [],
    );
  }

  Future<void> filterByCity(int? cityId) async {
    final current = state;
    if (current is! PeopleListSuccess) return;
    var neighborhoods = const <Neighborhood>[];
    if (cityId != null) {
      final result =
          await _neighborhoodRepository.getNeighborhoods(cityId: cityId, pageIndex: 1, pageSize: _refPageSize);
      neighborhoods = result.fold((_) => const <Neighborhood>[], (p) => p.items);
    }
    await _refetch(
      current,
      groupId: current.selectedGroupId,
      subGroupId: current.selectedSubGroupId,
      governorateId: current.selectedGovernorateId,
      cityId: cityId,
      neighborhoodId: null, // a neighborhood belongs to the previous city — reset
      search: current.search,
      neighborhoods: neighborhoods,
    );
  }

  Future<void> filterByNeighborhood(int? neighborhoodId) async {
    final current = state;
    if (current is! PeopleListSuccess) return;
    await _refetch(
      current,
      groupId: current.selectedGroupId,
      subGroupId: current.selectedSubGroupId,
      governorateId: current.selectedGovernorateId,
      cityId: current.selectedCityId,
      neighborhoodId: neighborhoodId,
      search: current.search,
    );
  }

  /// Clears the subgroup + all 3 location filters in one refetch — leaves the
  /// group filter untouched, since it has its own always-visible chip row
  /// outside the filter sheet these 4 dimensions live in.
  Future<void> clearSubGroupAndLocationFilters() async {
    final current = state;
    if (current is! PeopleListSuccess) return;
    await _refetch(
      current,
      groupId: current.selectedGroupId,
      subGroupId: null,
      governorateId: null,
      cityId: null,
      neighborhoodId: null,
      search: current.search,
      cities: const [],
      neighborhoods: const [],
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! PeopleListSuccess || !current.hasNextPage || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    final result = await _personRepository.getPersons(
      groupId: current.selectedGroupId,
      subGroupId: current.selectedSubGroupId,
      governorateId: current.selectedGovernorateId,
      cityId: current.selectedCityId,
      neighborhoodId: current.selectedNeighborhoodId,
      search: current.search,
      pageIndex: current.pageIndex + 1,
      pageSize: _pageSize,
    );
    result.fold(
      (failure) => emit(current.copyWith(
        isLoadingMore: false,
        loadMoreErrorMessage: core.failureToMessage(failure),
        loadMoreErrorId: current.loadMoreErrorId + 1,
      )),
      (page) => emit(current.copyWith(
        people: [...current.people, ...page.items],
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
        isLoadingMore: false,
      )),
    );
  }

  /// Re-fetches page 1 with the current filters/search, without a `Loading`
  /// flash — triggered by [DataRefreshBus] on a `people` scope notification
  /// (a person was added/edited/removed elsewhere). Keeps the last-good list
  /// on a background failure rather than replacing it with an error screen.
  Future<void> refresh() async {
    final current = state;
    if (current is! PeopleListSuccess) return;
    final result = await _personRepository.getPersons(
      groupId: current.selectedGroupId,
      subGroupId: current.selectedSubGroupId,
      governorateId: current.selectedGovernorateId,
      cityId: current.selectedCityId,
      neighborhoodId: current.selectedNeighborhoodId,
      search: current.search,
      pageIndex: 1,
      pageSize: _pageSize,
    );
    result.fold(
      (_) {},
      (page) => emit(current.copyWith(people: page.items, pageIndex: page.pageIndex, hasNextPage: page.hasNextPage)),
    );
  }

  /// Re-fetches only the group-filter chip row — triggered by
  /// [DataRefreshBus] on a `groups` scope notification (a group was
  /// created/renamed elsewhere), without touching the current people page.
  Future<void> refreshGroups() async {
    final current = state;
    if (current is! PeopleListSuccess) return;
    final result = await _groupRepository.getGroups(pageIndex: 1, pageSize: _refPageSize);
    result.fold((_) {}, (page) => emit(current.copyWith(groups: page.items)));
  }

  /// Re-fetches the option lists for whichever classification filters are
  /// currently in play (governorates always; subgroups/cities/neighborhoods
  /// only when their parent is selected) — triggered by [DataRefreshBus] on a
  /// `classification` scope notification. Never touches the current people
  /// page or the active selections themselves.
  Future<void> refreshClassificationFilters() async {
    final current = state;
    if (current is! PeopleListSuccess) return;

    final governoratesResult = await _governorateRepository.getGovernorates(pageIndex: 1, pageSize: _refPageSize);
    final governorates = governoratesResult.fold((_) => current.governorates, (p) => p.items);

    var subGroups = current.subGroups;
    if (current.selectedGroupId != null) {
      final result = await _subGroupRepository.getSubGroups(
        groupId: current.selectedGroupId!,
        pageIndex: 1,
        pageSize: _refPageSize,
      );
      subGroups = result.fold((_) => current.subGroups, (p) => p.items);
    }

    var cities = current.cities;
    if (current.selectedGovernorateId != null) {
      final result = await _cityRepository.getCities(
        governorateId: current.selectedGovernorateId!,
        pageIndex: 1,
        pageSize: _refPageSize,
      );
      cities = result.fold((_) => current.cities, (p) => p.items);
    }

    var neighborhoods = current.neighborhoods;
    if (current.selectedCityId != null) {
      final result = await _neighborhoodRepository.getNeighborhoods(
        cityId: current.selectedCityId!,
        pageIndex: 1,
        pageSize: _refPageSize,
      );
      neighborhoods = result.fold((_) => current.neighborhoods, (p) => p.items);
    }

    emit(current.copyWith(
      governorates: governorates,
      subGroups: subGroups,
      cities: cities,
      neighborhoods: neighborhoods,
    ));
  }

  /// Re-fetches page 1 for a fully-specified set of filters/search (callers
  /// always pass all 5 dimensions — either carried over from [current] or a
  /// new value) and emits the resulting [PeopleListSuccess]. The single path
  /// every filter mutator and search funnels through, so the `getPersons(...)`
  /// call and its state reconstruction exist exactly once.
  Future<void> _refetch(
    PeopleListSuccess current, {
    required int? groupId,
    required int? subGroupId,
    required int? governorateId,
    required int? cityId,
    required int? neighborhoodId,
    required String? search,
    List<SubGroup>? subGroups,
    List<City>? cities,
    List<Neighborhood>? neighborhoods,
  }) async {
    final result = await _personRepository.getPersons(
      groupId: groupId,
      subGroupId: subGroupId,
      governorateId: governorateId,
      cityId: cityId,
      neighborhoodId: neighborhoodId,
      search: search,
      pageIndex: 1,
      pageSize: _pageSize,
    );
    result.fold(
      (failure) => emit(PeopleListError(core.failureToMessage(failure))),
      (page) => emit(PeopleListSuccess(
        people: page.items,
        groups: current.groups,
        selectedGroupId: groupId,
        subGroups: subGroups ?? current.subGroups,
        selectedSubGroupId: subGroupId,
        governorates: current.governorates,
        selectedGovernorateId: governorateId,
        cities: cities ?? current.cities,
        selectedCityId: cityId,
        neighborhoods: neighborhoods ?? current.neighborhoods,
        selectedNeighborhoodId: neighborhoodId,
        search: search,
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
      )),
    );
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    _refreshSubscription.cancel();
    return super.close();
  }
}
