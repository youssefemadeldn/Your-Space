import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/governorate.dart';
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

  /// Only the first 50 already-added guests are excluded — the same
  /// personal-scale tradeoff the backend itself makes for reciprocity
  /// suggestions (`EventGuestService.cs` comment) — there's no
  /// `GET /Persons?excludeEventId=` filter to do this exactly server-side.
  Set<int> _existingGuestPersonIds = {};

  Future<void> load(int eventId) async {
    emit(const AddGuestsListLoading());

    final existingGuestsResult =
        await _eventGuestRepository.getEventGuests(eventId, pageIndex: 1, pageSize: 50);
    _existingGuestPersonIds = existingGuestsResult.fold(
      (_) => const <int>{},
      (page) => page.items.map((g) => g.personId).toSet(),
    );

    final progressResult = await _eventGuestRepository.getProgress(eventId);
    final groupProgress =
        progressResult.fold((_) => const <GroupGuestProgress>[], (progress) => progress.groups);

    final governoratesResult = await _governorateRepository.getGovernorates(pageIndex: 1, pageSize: _refPageSize);
    final governorates = governoratesResult.fold((_) => const <Governorate>[], (page) => page.items);

    final peopleResult = await _personRepository.getPersons(pageIndex: 1, pageSize: _pageSize);
    peopleResult.fold(
      (failure) => emit(AddGuestsListError(core.failureToMessage(failure))),
      (page) => emit(AddGuestsListSuccess(
        availablePeople: page.items.where((p) => !_existingGuestPersonIds.contains(p.id)).toList(),
        groupProgress: groupProgress,
        governorates: governorates,
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
      )),
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! AddGuestsListSuccess || !current.hasNextPage || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    final result =
        await _personRepository.getPersons(pageIndex: current.pageIndex + 1, pageSize: _pageSize);
    result.fold(
      (failure) => emit(current.copyWith(isLoadingMore: false)),
      (page) => emit(current.copyWith(
        availablePeople: [
          ...current.availablePeople,
          ...page.items.where((p) => !_existingGuestPersonIds.contains(p.id)),
        ],
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
        isLoadingMore: false,
      )),
    );
  }

  /// Populates the "by subgroup" tab's child list once its own local
  /// parent-picker state selects a group.
  Future<void> loadSubGroupsForGroup(int groupId) async {
    final current = state;
    if (current is! AddGuestsListSuccess) return;
    final result = await _subGroupRepository.getSubGroups(groupId: groupId, pageIndex: 1, pageSize: _refPageSize);
    result.fold(
      (_) {},
      (page) => emit(current.copyWith(subGroupOptions: page.items)),
    );
  }

  /// Populates the "by city" tab's child list (and the "by neighborhood"
  /// tab's intermediate city picker) once a governorate is selected.
  Future<void> loadCitiesForGovernorate(int governorateId) async {
    final current = state;
    if (current is! AddGuestsListSuccess) return;
    final result =
        await _cityRepository.getCities(governorateId: governorateId, pageIndex: 1, pageSize: _refPageSize);
    result.fold(
      (_) {},
      (page) => emit(current.copyWith(cityOptions: page.items)),
    );
  }

  /// Populates the "by neighborhood" tab's child list once a city is selected.
  Future<void> loadNeighborhoodsForCity(int cityId) async {
    final current = state;
    if (current is! AddGuestsListSuccess) return;
    final result =
        await _neighborhoodRepository.getNeighborhoods(cityId: cityId, pageIndex: 1, pageSize: _refPageSize);
    result.fold(
      (_) {},
      (page) => emit(current.copyWith(neighborhoodOptions: page.items)),
    );
  }
}
