import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/classification/domain/repositories/base_subgroup_repository.dart';

import 'subgroup_action_state.dart';

/// No `DataRefreshBus` notification on success (retired in row 8.15, mirrors
/// `CityActionCubit`'s own 8.9 retirement): `SubGroupRepositoryImpl`'s
/// create/update/delete already write straight into drift via the outbox,
/// so every open `watchSubGroups` stream — including `SubGroupListCubit`'s —
/// sees the change directly (design doc §7).
@injectable
class SubGroupActionCubit extends Cubit<SubGroupActionState> {
  final SubGroupRepository _subGroupRepository;

  SubGroupActionCubit(this._subGroupRepository) : super(const SubGroupActionInitial());

  Future<void> createSubGroup({required int groupId, required String name, String? nameAr}) async {
    emit(const SubGroupActionSubmitting());
    final result = await _subGroupRepository.createSubGroup(groupId: groupId, name: name, nameAr: nameAr);
    result.fold(
      (failure) => emit(SubGroupActionError(core.failureToMessage(failure))),
      (subGroup) => emit(SubGroupActionSaveSuccess(subGroup)),
    );
  }

  Future<void> updateSubGroup({
    required int groupId,
    required int id,
    required String name,
    String? nameAr,
  }) async {
    emit(const SubGroupActionSubmitting());
    final result = await _subGroupRepository.updateSubGroup(groupId: groupId, id: id, name: name, nameAr: nameAr);
    result.fold(
      (failure) => emit(SubGroupActionError(core.failureToMessage(failure))),
      (subGroup) => emit(SubGroupActionSaveSuccess(subGroup)),
    );
  }

  Future<void> deleteSubGroup({required int groupId, required int id}) async {
    emit(const SubGroupActionSubmitting());
    final result = await _subGroupRepository.deleteSubGroup(groupId: groupId, id: id);
    result.fold(
      (failure) => emit(SubGroupActionError(core.failureToMessage(failure))),
      (_) => emit(const SubGroupActionDeleteSuccess()),
    );
  }
}
