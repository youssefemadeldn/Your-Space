import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/classification/domain/repositories/base_subgroup_repository.dart';

import 'subgroup_action_state.dart';

@injectable
class SubGroupActionCubit extends Cubit<SubGroupActionState> {
  final SubGroupRepository _subGroupRepository;
  final DataRefreshBus _dataRefreshBus;

  SubGroupActionCubit(this._subGroupRepository, this._dataRefreshBus) : super(const SubGroupActionInitial());

  Future<void> createSubGroup({required int groupId, required String name, String? nameAr}) async {
    emit(const SubGroupActionSubmitting());
    final result = await _subGroupRepository.createSubGroup(groupId: groupId, name: name, nameAr: nameAr);
    result.fold(
      (failure) => emit(SubGroupActionError(core.failureToMessage(failure))),
      (subGroup) {
        _dataRefreshBus.notify(DataScope.classification);
        emit(SubGroupActionSaveSuccess(subGroup));
      },
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
      (subGroup) {
        _dataRefreshBus.notify(DataScope.classification);
        emit(SubGroupActionSaveSuccess(subGroup));
      },
    );
  }

  Future<void> deleteSubGroup({required int groupId, required int id}) async {
    emit(const SubGroupActionSubmitting());
    final result = await _subGroupRepository.deleteSubGroup(groupId: groupId, id: id);
    result.fold(
      (failure) => emit(SubGroupActionError(core.failureToMessage(failure))),
      (_) {
        _dataRefreshBus.notify(DataScope.classification);
        emit(const SubGroupActionDeleteSuccess());
      },
    );
  }
}
