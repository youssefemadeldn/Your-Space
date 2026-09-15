import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/governorate.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/classification/domain/repositories/base_city_repository.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_governorate_repository.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_neighborhood_repository.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_subgroup_repository.dart';
import 'package:your_space_mobile/features/events/domain/entities/group_guest_progress.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_guest_repository.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';

import 'add_guests_list_state.dart';

const _pageSize = 20;
const _refPageSize = 50;

@injectable
class AddGuestsListCubit extends Cubit<AddGuestsListState> {
  final PersonRepository _personRepository;
  final EventGuestRepository _eventGuestRepository;
  final SubGroupRepository _subGroupRepository;
  final GovernorateRepository _governorateRepository;
  final CityRepository _cityRepository;
  final NeighborhoodRepository _neighborhoodRepository;

  AddGuestsListCubit(
    this._personRepository,
    this._eventGuestRepository,
    this._subGroupRepository,
    this._governorateRepository,
    this._cityRepository,
    this._neighborhoodRepository,
  ) : super(const AddGuestsListInitial());

  /// Every already-added guest for this event, from the local drift cache
  /// (row 9.8) — this is the user's complete guest set for the event, not
  /// just a first page.
  Set<int> _existingGuestPersonIds = {};
  StreamSubscription<List<Person>>? _peopleSubscription;

  Future<void> load(int eventId) async {
    emit(const AddGuestsListLoading());

    // EventGuest is local-first (row 9.8) — a local read can't fail the way
    // a network call can.
    final existingGuests =
        await _eventGuestRepository.watchEventGuests(eventId: eventId, limit: 1000000).first;
    _existingGuestPersonIds = existingGuests.map((g) => g.personId).toSet();

    final progressResult = await _eventGuestRepository.getProgress(eventId);
    final groupProgress =
        progressResult.fold((_) => const <GroupGuestProgress>[], (progress) => progress.groups);

    // Governorate is local-first (row 8.2) — a local read can't fail the way
    // a network call can.
    final governorates = await _governorateRepository.watchGovernorates(limit: _refPageSize).first;

    await _subscribeToPeople(limit: _pageSize, groupProgress: groupProgress, governorates: governorates);
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! AddGuestsListSuccess || !current.hasNextPage || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    await _subscribeToPeople(limit: current.limit + _pageSize);
  }

  /// Cancels any existing local subscription and resubscribes to
  /// `watchPersons(limit: limit)` — Person is local-first (CLAUDE.md
  /// Architecture rule 7), so the "available people" list reads from the
  /// local drift store instead of a remote page fetch. Mirrors
  /// `PeopleListCubit._subscribeToPersons`/`CityListCubit._subscribeToCities`.
  /// [groupProgress]/[governorates] are only passed on the very first call
  /// (from [load]) — later calls (`loadMore`) fall back to whatever is
  /// already in the current [AddGuestsListSuccess].
  Future<void> _subscribeToPeople({
    required int limit,
    List<GroupGuestProgress>? groupProgress,
    List<Governorate>? governorates,
  }) async {
    await _peopleSubscription?.cancel();
    final done = Completer<void>();

    void handleError(Object error) {
      emit(AddGuestsListError(core.failureToMessage(const CacheFailure())));
      if (!done.isCompleted) done.complete();
    }

    _peopleSubscription = _personRepository.watchPersons(limit: limit).listen(
      (people) async {
        try {
          final total = await _personRepository.countPersons();
          final available = people.where((p) => !_existingGuestPersonIds.contains(p.id)).toList();
          final base = state;
          emit(AddGuestsListSuccess(
            availablePeople: available,
            groupProgress: groupProgress ?? (base is AddGuestsListSuccess ? base.groupProgress : const []),
            governorates: governorates ?? (base is AddGuestsListSuccess ? base.governorates : const []),
            subGroupOptions: base is AddGuestsListSuccess ? base.subGroupOptions : const [],
            cityOptions: base is AddGuestsListSuccess ? base.cityOptions : const [],
            neighborhoodOptions: base is AddGuestsListSuccess ? base.neighborhoodOptions : const [],
            limit: limit,
            hasNextPage: people.length < total,
          ));
          if (!done.isCompleted) done.complete();
        } catch (error) {
          handleError(error);
        }
      },
      onError: (Object error) => handleError(error),
    );
    await done.future;
  }

  /// Populates the "by subgroup" tab's child list once its own local
  /// parent-picker state selects a group.
  Future<void> loadSubGroupsForGroup(int groupId) async {
    final current = state;
    if (current is! AddGuestsListSuccess) return;
    // SubGroup is local-first (row 8.14) — a local read can't fail the way a
    // network call can.
    final subGroups = await _subGroupRepository.watchSubGroups(groupId: groupId, limit: _refPageSize).first;
    emit(current.copyWith(subGroupOptions: subGroups));
  }

  /// Populates the "by city" tab's child list (and the "by neighborhood"
  /// tab's intermediate city picker) once a governorate is selected.
  Future<void> loadCitiesForGovernorate(int governorateId) async {
    final current = state;
    if (current is! AddGuestsListSuccess) return;
    // City is local-first (row 8.8) — a local read can't fail the way a
    // network call can.
    final cities = await _cityRepository.watchCities(governorateId: governorateId, limit: _refPageSize).first;
    emit(current.copyWith(cityOptions: cities));
  }

  /// Populates the "by neighborhood" tab's child list once a city is selected.
  Future<void> loadNeighborhoodsForCity(int cityId) async {
    final current = state;
    if (current is! AddGuestsListSuccess) return;
    // Neighborhood is local-first (row 8.20) — a local read can't fail the
    // way a network call can.
    final neighborhoods = await _neighborhoodRepository.watchNeighborhoods(cityId: cityId, limit: _refPageSize).first;
    emit(current.copyWith(neighborhoodOptions: neighborhoods));
  }

  @override
  Future<void> close() {
    _peopleSubscription?.cancel();
    return super.close();
  }
}
