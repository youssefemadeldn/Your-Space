import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/mock/entities/invite_method.dart';
import 'package:your_space_mobile/core/mock/mock_data_store.dart';

import 'add_occasion_state.dart';

@injectable
class AddOccasionCubit extends Cubit<AddOccasionState> {
  final MockDataStore _store;

  AddOccasionCubit(this._store) : super(const AddOccasionInitial());

  Future<void> submit({
    required int personId,
    required bool invitedMe,
    InviteMethod? inviteMethod,
    String? occasionName,
    DateTime? occasionDate,
    String? notes,
  }) async {
    emit(const AddOccasionSubmitting());
    await Future.delayed(_store.simulatedLatency);
    final entry = _store.addOccasionHistory(
      personId: personId,
      invitedMe: invitedMe,
      inviteMethod: inviteMethod,
      occasionName: occasionName,
      occasionDate: occasionDate,
      notes: notes,
    );
    emit(AddOccasionSuccess(entry));
  }
}
