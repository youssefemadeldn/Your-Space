import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/events/domain/repositories/base_event_guest_repository.dart';

import 'add_guests_action_state.dart';

/// Shared between the Add-Guests screen (both tabs) and Reciprocity
/// Suggestions — "add as guest" there is the exact same bulk-add operation
/// with a single-element `personIds` list.
@injectable
class AddGuestsActionCubit extends Cubit<AddGuestsActionState> {
  final EventGuestRepository _eventGuestRepository;

  AddGuestsActionCubit(this._eventGuestRepository) : super(const AddGuestsActionInitial());

  Future<void> addPersons({required int eventId, required List<int> personIds}) async {
    emit(AddGuestsActionSubmitting(personIds: personIds));
    final result = await _eventGuestRepository.addPersonsToEvent(eventId: eventId, personIds: personIds);
    result.fold(
      (failure) => emit(AddGuestsActionError(core.failureToMessage(failure))),
      (bulkResult) => emit(AddGuestsActionSuccess(bulkResult)),
    );
  }

  Future<void> addGroup({required int eventId, required int groupId}) async {
    emit(AddGuestsActionSubmitting(groupId: groupId));
    final result = await _eventGuestRepository.addGroupToEvent(eventId: eventId, groupId: groupId);
    result.fold(
      (failure) => emit(AddGuestsActionError(core.failureToMessage(failure))),
      (bulkResult) => emit(AddGuestsActionSuccess(bulkResult)),
    );
  }
}
