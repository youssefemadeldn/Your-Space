import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/city.dart';
import 'package:your_space_mobile/core/entities/governorate.dart';
import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/entities/neighborhood.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/entities/subgroup.dart';
import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/core/network/failure.dart';
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
///
/// People is local-first (CLAUDE.md Architecture rule 7): the people list
/// itself is read from a reactive drift `Stream` via `watchPersons()`, with
/// `refreshPersons()` running the network leg in the background. The
/// reference/filter-option lists (groups, subgroups, governorates, cities,
/// neighborhoods) are all local-first too — each is a one-shot
/// `watchXxx(...).first` read off the local drift store, not a network call.
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
  StreamSubscription<List<Person>>? _peopleSubscription;

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
        case DataScope.groups:
          refreshGroups();
        case DataScope.people:
        case DataScope.events:
        case DataScope.eventGuests:
        case DataScope.profile:
          break;
      }
    });
  }

  Future<void> load() async {
    emit(const PeopleListLoading());
    // Group is local-first (CLAUDE.md Architecture rule 7) — a local read
    // can't fail the way a network call can.
    final groups = await _groupRepository.watchGroups(limit: _refPageSize).first;
    // Governorate is local-first (row 8.2) — a local read can't fail the way
    // a network call can.
    final governorates = await _governorateRepository.watchGovernorates(limit: _refPageSize).first;

    await _subscribeToPersons(
      groupId: null,
      subGroupId: null,
      governorateId: null,
      cityId: null,
      neighborhoodId: null,
      search: null,
      limit: _pageSize,
      groups: groups,
      governorates: governorates,
    );
    // Background network leg — the first render already came from the local
    // cache above; a failure here is swallowed (design doc §3), the UI just
    // keeps showing whatever was cached.
    unawaited(_personRepository.refreshPersons());
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
    await _subscribeToPersons(
      groupId: current.selectedGroupId,
      subGroupId: current.selectedSubGroupId,
      governorateId: current.selectedGovernorateId,
      cityId: current.selectedCityId,
      neighborhoodId: current.selectedNeighborhoodId,
      search: query.isEmpty ? null : query,
      limit: _pageSize,
    );
  }

  Future<void> filterByGroup(int? groupId) async {
    final current = state;
    if (current is! PeopleListSuccess) return;
    var subGroups = const <SubGroup>[];
    if (groupId != null) {
      subGroups = await _subGroupRepository.watchSubGroups(groupId: groupId, limit: _refPageSize).first;
    }
    await _subscribeToPersons(
      groupId: groupId,
      subGroupId: null, // a subgroup belongs to the previous group — reset
      governorateId: current.selectedGovernorateId,
      cityId: current.selectedCityId,
      neighborhoodId: current.selectedNeighborhoodId,
      search: current.search,
      limit: _pageSize,
      subGroups: subGroups,
    );
  }

  Future<void> filterBySubGroup(int? subGroupId) async {
    final current = state;
    if (current is! PeopleListSuccess) return;
    await _subscribeToPersons(
      groupId: current.selectedGroupId,
      subGroupId: subGroupId,
      governorateId: current.selectedGovernorateId,
      cityId: current.selectedCityId,
      neighborhoodId: current.selectedNeighborhoodId,
      search: current.search,
      limit: _pageSize,
    );
  }

  Future<void> filterByGovernorate(int? governorateId) async {
    final current = state;
    if (current is! PeopleListSuccess) return;
    var cities = const <City>[];
    if (governorateId != null) {
      // City is local-first (row 8.8) — a local read can't fail the way a
      // network call can.
      cities = await _cityRepository.watchCities(governorateId: governorateId, limit: _refPageSize).first;
    }
    await _subscribeToPersons(
      groupId: current.selectedGroupId,
      subGroupId: current.selectedSubGroupId,
      governorateId: governorateId,
      cityId: null, // a city belongs to the previous governorate — reset
      neighborhoodId: null,
      search: current.search,
      limit: _pageSize,
      cities: cities,
      neighborhoods: const [],
    );
  }

  Future<void> filterByCity(int? cityId) async {
    final current = state;
    if (current is! PeopleListSuccess) return;
    var neighborhoods = const <Neighborhood>[];
    if (cityId != null) {
      // Neighborhood is local-first (row 8.20) — a local read can't fail the
      // way a network call can.
      neighborhoods = await _neighborhoodRepository.watchNeighborhoods(cityId: cityId, limit: _refPageSize).first;
    }
    await _subscribeToPersons(
      groupId: current.selectedGroupId,
      subGroupId: current.selectedSubGroupId,
      governorateId: current.selectedGovernorateId,
      cityId: cityId,
      neighborhoodId: null, // a neighborhood belongs to the previous city — reset
      search: current.search,
      limit: _pageSize,
      neighborhoods: neighborhoods,
    );
  }

  Future<void> filterByNeighborhood(int? neighborhoodId) async {
    final current = state;
    if (current is! PeopleListSuccess) return;
    await _subscribeToPersons(
      groupId: current.selectedGroupId,
      subGroupId: current.selectedSubGroupId,
      governorateId: current.selectedGovernorateId,
      cityId: current.selectedCityId,
      neighborhoodId: neighborhoodId,
      search: current.search,
      limit: _pageSize,
    );
  }

  /// Clears the subgroup + all 3 location filters in one refetch — leaves the
  /// group filter untouched, since it has its own always-visible chip row
  /// outside the filter sheet these 4 dimensions live in.
  Future<void> clearSubGroupAndLocationFilters() async {
    final current = state;
    if (current is! PeopleListSuccess) return;
    await _subscribeToPersons(
      groupId: current.selectedGroupId,
      subGroupId: null,
      governorateId: null,
      cityId: null,
      neighborhoodId: null,
      search: current.search,
      limit: _pageSize,
      cities: const [],
      neighborhoods: const [],
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! PeopleListSuccess || !current.hasNextPage || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    await _subscribeToPersons(
      groupId: current.selectedGroupId,
      subGroupId: current.selectedSubGroupId,
      governorateId: current.selectedGovernorateId,
      cityId: current.selectedCityId,
      neighborhoodId: current.selectedNeighborhoodId,
      search: current.search,
      limit: current.limit + _pageSize,
      onError: (_) => emit(current.copyWith(
        isLoadingMore: false,
        loadMoreErrorMessage: core.failureToMessage(const CacheFailure()),
        loadMoreErrorId: current.loadMoreErrorId + 1,
      )),
    );
  }

  /// Kicks off a background bulk sync (design doc §3) — the drift `Stream`
  /// already re-emits on upsert, so there's nothing to manually re-fetch or
  /// re-emit here. Failure is swallowed; the last-good cached list stays on
  /// screen.
  Future<void> refresh() async {
    if (state is! PeopleListSuccess) return;
    await _personRepository.refreshPersons();
  }

  /// Re-fetches only the group-filter chip row — triggered by
  /// [DataRefreshBus] on a `groups` scope notification (a group was
  /// created/renamed elsewhere), without touching the current people page.
  Future<void> refreshGroups() async {
    final current = state;
    if (current is! PeopleListSuccess) return;
    final groups = await _groupRepository.watchGroups(limit: _refPageSize).first;
    emit(current.copyWith(groups: groups));
  }

  /// Cancels any existing local subscription and resubscribes to
  /// `watchPersons(..., limit: limit)` for a fully-specified set of
  /// filters/search (callers always pass all 5 dimensions — either carried
  /// over from the current state or a new value) and an explicit [limit]
  /// (callers always pass `_pageSize` to reset, or `current.limit +
  /// _pageSize` to grow — never a separately-tracked field, so a failed
  /// `loadMore()` retry recomputes the same window instead of silently
  /// skipping a chunk). Every emission also resolves `hasNextPage` via a
  /// one-shot `countPersons` call before building the next
  /// [PeopleListSuccess]. The single path every filter mutator, search, and
  /// `loadMore()` funnels through.
  ///
  /// [onError] lets `loadMore()` report a failure through its own
  /// `loadMoreErrorMessage`/`loadMoreErrorId` retry-snackbar path instead of
  /// the default: replacing the whole screen with [PeopleListError].
  Future<void> _subscribeToPersons({
    required int? groupId,
    required int? subGroupId,
    required int? governorateId,
    required int? cityId,
    required int? neighborhoodId,
    required String? search,
    required int limit,
    List<Group>? groups,
    List<SubGroup>? subGroups,
    List<Governorate>? governorates,
    List<City>? cities,
    List<Neighborhood>? neighborhoods,
    void Function(Object error)? onError,
  }) async {
    await _peopleSubscription?.cancel();
    final done = Completer<void>();

    void handleError(Object error) {
      if (onError != null) {
        onError(error);
      } else {
        emit(PeopleListError(core.failureToMessage(const CacheFailure())));
      }
      if (!done.isCompleted) done.complete();
    }

    _peopleSubscription = _personRepository
        .watchPersons(
      groupId: groupId,
      subGroupId: subGroupId,
      governorateId: governorateId,
      cityId: cityId,
      neighborhoodId: neighborhoodId,
      search: search,
      limit: limit,
    )
        .listen(
      (people) async {
        try {
          final total = await _personRepository.countPersons(
            groupId: groupId,
            subGroupId: subGroupId,
            governorateId: governorateId,
            cityId: cityId,
            neighborhoodId: neighborhoodId,
            search: search,
          );
          final base = state;
          emit(PeopleListSuccess(
            people: people,
            groups: groups ?? (base is PeopleListSuccess ? base.groups : const []),
            selectedGroupId: groupId,
            subGroups: subGroups ?? (base is PeopleListSuccess ? base.subGroups : const []),
            selectedSubGroupId: subGroupId,
            governorates: governorates ?? (base is PeopleListSuccess ? base.governorates : const []),
            selectedGovernorateId: governorateId,
            cities: cities ?? (base is PeopleListSuccess ? base.cities : const []),
            selectedCityId: cityId,
            neighborhoods: neighborhoods ?? (base is PeopleListSuccess ? base.neighborhoods : const []),
            selectedNeighborhoodId: neighborhoodId,
            search: search,
            limit: limit,
            hasNextPage: people.length < total,
          ));
          if (!done.isCompleted) done.complete();
        } catch (error) {
          // Only the first emission's failure is the caller's problem (it's
          // awaited below); a later background emission's failure has no
          // caller left to report to and is swallowed, matching this cubit's
          // existing "background refresh failures don't replace the list"
          // posture.
          handleError(error);
        }
      },
      onError: (Object error) => handleError(error),
    );
    // Wait for the first emission so callers (load(), filter mutators,
    // loadMore()) can treat this like the old awaited Future-based refetch.
    await done.future;
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    _refreshSubscription.cancel();
    _peopleSubscription?.cancel();
    return super.close();
  }
}
