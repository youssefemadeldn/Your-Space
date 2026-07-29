import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/mock/mock_data_store.dart';

import 'reciprocity_suggestions_state.dart';

@injectable
class ReciprocitySuggestionsCubit extends Cubit<ReciprocitySuggestionsState> {
  final MockDataStore _store;

  ReciprocitySuggestionsCubit(this._store) : super(const ReciprocitySuggestionsInitial());

  int? _eventId;

  Future<void> load(int eventId) async {
    _eventId = eventId;
    emit(const ReciprocitySuggestionsLoading());
    await Future.delayed(_store.simulatedLatency);
    emit(ReciprocitySuggestionsSuccess(
      suggestions: _store.reciprocitySuggestions(eventId),
      groups: _store.groups(),
    ));
  }

  void filterByGroup(int? groupId) {
    final current = state;
    if (current is! ReciprocitySuggestionsSuccess) return;
    emit(ReciprocitySuggestionsSuccess(
      suggestions: _store.reciprocitySuggestions(_eventId!, groupId: groupId),
      groups: current.groups,
      selectedGroupId: groupId,
    ));
  }

  /// Re-queries without a `Loading` flash, used after a person is added as a
  /// guest elsewhere — they're no longer a valid suggestion once added.
  void refresh() {
    final current = state;
    if (current is! ReciprocitySuggestionsSuccess) return;
    emit(ReciprocitySuggestionsSuccess(
      suggestions: _store.reciprocitySuggestions(_eventId!, groupId: current.selectedGroupId),
      groups: current.groups,
      selectedGroupId: current.selectedGroupId,
    ));
  }
}
