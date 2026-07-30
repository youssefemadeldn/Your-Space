import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/invite_method.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';

import 'add_occasion_state.dart';

@injectable
class AddOccasionCubit extends Cubit<AddOccasionState> {
  final PersonRepository _personRepository;

  AddOccasionCubit(this._personRepository) : super(const AddOccasionInitial());

  Future<void> submit({
    required int personId,
    required bool invitedMe,
    InviteMethod? inviteMethod,
    String? occasionName,
    DateTime? occasionDate,
    String? notes,
  }) async {
    emit(const AddOccasionSubmitting());
    final result = await _personRepository.addOccasionHistory(
      personId: personId,
      invitedMe: invitedMe,
      inviteMethod: inviteMethod,
      occasionName: occasionName,
      occasionDate: occasionDate,
      notes: notes,
    );
    result.fold(
      (failure) => emit(AddOccasionError(core.failureToMessage(failure))),
      (entry) => emit(AddOccasionSuccess(entry)),
    );
  }
}
