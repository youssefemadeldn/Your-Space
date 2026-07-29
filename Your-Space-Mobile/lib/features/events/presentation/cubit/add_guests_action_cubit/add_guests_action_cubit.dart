import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/mock/mock_data_store.dart';

import 'add_guests_action_state.dart';

/// Shared between the Add-Guests screen (both tabs) and Reciprocity
/// Suggestions — "add as guest" there is the exact same bulk-add operation
/// with a single-element `personIds` list.
@injectable
class AddGuestsActionCubit extends Cubit<AddGuestsActionState> {
  final MockDataStore _store;

  AddGuestsActionCubit(this._store) : super(const AddGuestsActionInitial());

  Future<void> addPersons({required int eventId, required List<int> personIds}) async {
    emit(const AddGuestsActionSubmitting());
    await Future.delayed(_store.simulatedLatency);
    emit(AddGuestsActionSuccess(_store.addPersonsToEvent(eventId: eventId, personIds: personIds)));
  }

  Future<void> addGroup({required int eventId, required int groupId}) async {
    emit(const AddGuestsActionSubmitting());
    await Future.delayed(_store.simulatedLatency);
    emit(AddGuestsActionSuccess(_store.addGroupToEvent(eventId: eventId, groupId: groupId)));
  }
}
