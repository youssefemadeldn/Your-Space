import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';

import 'group_action_state.dart';

@injectable
class GroupActionCubit extends Cubit<GroupActionState> {
  final GroupRepository _groupRepository;
  final DataRefreshBus _dataRefreshBus;

  GroupActionCubit(this._groupRepository, this._dataRefreshBus) : super(const GroupActionInitial());

  Future<void> createGroup({required String name, String? nameAr}) async {
    emit(const GroupActionSubmitting());
    final result = await _groupRepository.createGroup(name: name, nameAr: nameAr);
    result.fold(
      (failure) => emit(GroupActionError(core.failureToMessage(failure))),
      (group) {
        _dataRefreshBus.notify(DataScope.groups);
        emit(GroupActionSuccess(group));
      },
    );
  }

  Future<void> updateGroup({required int id, required String name, String? nameAr}) async {
    emit(const GroupActionSubmitting());
    final result = await _groupRepository.updateGroup(id: id, name: name, nameAr: nameAr);
    result.fold(
      (failure) => emit(GroupActionError(core.failureToMessage(failure))),
      (group) {
        _dataRefreshBus.notify(DataScope.groups);
        emit(GroupActionSuccess(group));
      },
    );
  }
}
