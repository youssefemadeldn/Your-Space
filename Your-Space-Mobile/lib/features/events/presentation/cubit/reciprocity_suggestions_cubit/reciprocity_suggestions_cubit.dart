import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/events/domain/repositories/base_event_guest_repository.dart';
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';

import 'reciprocity_suggestions_state.dart';

const _pageSize = 20;

@injectable
class ReciprocitySuggestionsCubit extends Cubit<ReciprocitySuggestionsState> {
  final EventGuestRepository _eventGuestRepository;
  final GroupRepository _groupRepository;

  ReciprocitySuggestionsCubit(this._eventGuestRepository, this._groupRepository)
      : super(const ReciprocitySuggestionsInitial());

  int? _eventId;

  Future<void> load(int eventId) async {
    _eventId = eventId;
    emit(const ReciprocitySuggestionsLoading());
    final groupsResult = await _groupRepository.getGroups(pageIndex: 1, pageSize: 50);
    final groups = groupsResult.fold((_) => const <Group>[], (page) => page.items);
    final result =
        await _eventGuestRepository.getReciprocitySuggestions(eventId, pageIndex: 1, pageSize: _pageSize);
    result.fold(
      (failure) => emit(ReciprocitySuggestionsError(core.failureToMessage(failure))),
      (page) => emit(ReciprocitySuggestionsSuccess(
        suggestions: page.items,
        groups: groups,
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
      )),
    );
  }

  Future<void> filterByGroup(int? groupId) async {
    final current = state;
    if (current is! ReciprocitySuggestionsSuccess) return;
    final result = await _eventGuestRepository.getReciprocitySuggestions(
      _eventId!,
      groupId: groupId,
      pageIndex: 1,
      pageSize: _pageSize,
    );
    result.fold(
      (failure) => emit(ReciprocitySuggestionsError(core.failureToMessage(failure))),
      (page) => emit(ReciprocitySuggestionsSuccess(
        suggestions: page.items,
        groups: current.groups,
        selectedGroupId: groupId,
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
      )),
    );
  }

  /// Re-queries page 1 without a `Loading` flash — used after a person is
  /// added as a guest elsewhere; they're no longer a valid suggestion once
  /// added.
  Future<void> refresh() async {
    final current = state;
    if (current is! ReciprocitySuggestionsSuccess) return;
    final result = await _eventGuestRepository.getReciprocitySuggestions(
      _eventId!,
      groupId: current.selectedGroupId,
      pageIndex: 1,
      pageSize: _pageSize,
    );
    result.fold(
      (failure) => emit(ReciprocitySuggestionsError(core.failureToMessage(failure))),
      (page) => emit(ReciprocitySuggestionsSuccess(
        suggestions: page.items,
        groups: current.groups,
        selectedGroupId: current.selectedGroupId,
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
      )),
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! ReciprocitySuggestionsSuccess || !current.hasNextPage || current.isLoadingMore) {
      return;
    }
    emit(current.copyWith(isLoadingMore: true));
    final result = await _eventGuestRepository.getReciprocitySuggestions(
      _eventId!,
      groupId: current.selectedGroupId,
      pageIndex: current.pageIndex + 1,
      pageSize: _pageSize,
    );
    result.fold(
      (failure) => emit(current.copyWith(isLoadingMore: false)),
      (page) => emit(current.copyWith(
        suggestions: [...current.suggestions, ...page.items],
        pageIndex: page.pageIndex,
        hasNextPage: page.hasNextPage,
        isLoadingMore: false,
      )),
    );
  }
}
