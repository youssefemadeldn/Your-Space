import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';

import 'people_list_state.dart';

const _pageSize = 20;

@injectable
class PeopleListCubit extends Cubit<PeopleListState> {
  final PersonRepository _personRepository;
  final GroupRepository _groupRepository;
  Timer? _searchDebounce;

  PeopleListCubit(this._personRepository, this._groupRepository) : super(const PeopleListInitial());

  Future<void> load() async {
    emit(const PeopleListLoading());
    final groupsResult = await _groupRepository.getGroups(pageIndex: 1, pageSize: 50);
    final groups = groupsResult.fold((_) => const <Group>[], (page) => page.items);
    final peopleResult = await _personRepository.getPersons(pageIndex: 1, pageSize: _pageSize);
    peopleResult.fold(
      (failure) => emit(PeopleListError(core.failureToMessage(failure))),
      (page) => emit(PeopleListSuccess(
        people: page.items,
        groups: groups,
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
    final search = query.isEmpty ? null : query;
    final result = await _personRepository.getPersons(
      groupId: current.selectedGroupId,
      search: search,
      pageIndex: 1,
      pageSize: _pageSize,
    );
    result.fold(
      (failure) => emit(PeopleListError(core.failureToMessage(failure))),
      (page) => emit(PeopleListSuccess(
        people: page.items,
        groups: current.groups,
        selectedGroupId: current.selectedGroupId,
        search: search,
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
      )),
    );
  }

  Future<void> filterByGroup(int? groupId) async {
    final current = state;
    if (current is! PeopleListSuccess) return;
    final result =
        await _personRepository.getPersons(groupId: groupId, pageIndex: 1, pageSize: _pageSize);
    result.fold(
      (failure) => emit(PeopleListError(core.failureToMessage(failure))),
      (page) => emit(PeopleListSuccess(
        people: page.items,
        groups: current.groups,
        selectedGroupId: groupId,
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
      )),
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! PeopleListSuccess || !current.hasNextPage || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    final result = await _personRepository.getPersons(
      groupId: current.selectedGroupId,
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

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
