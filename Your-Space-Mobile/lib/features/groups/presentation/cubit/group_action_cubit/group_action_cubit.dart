import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';

import 'group_action_state.dart';

/// No `DataRefreshBus` notification on success (retired in row 7.3):
/// `GroupRepositoryImpl.createGroup`/`updateGroup` already write straight
/// into drift via the outbox, so every open `watchGroups` stream —
/// including `GroupsListCubit`'s, a shell-branch cubit built once by
/// `IndexedStack` — sees the change directly (design doc §7).
@injectable
class GroupActionCubit extends Cubit<GroupActionState> {
  final GroupRepository _groupRepository;

  GroupActionCubit(this._groupRepository) : super(const GroupActionInitial());

  Future<void> createGroup({required String name, String? nameAr}) async {
    emit(const GroupActionSubmitting());
    final result = await _groupRepository.createGroup(name: name, nameAr: nameAr);
    result.fold(
      (failure) => emit(GroupActionError(core.failureToMessage(failure))),
      (group) => emit(GroupActionSuccess(group)),
    );
  }

  Future<void> updateGroup({required int id, required String name, String? nameAr}) async {
    emit(const GroupActionSubmitting());
    final result = await _groupRepository.updateGroup(id: id, name: name, nameAr: nameAr);
    result.fold(
      (failure) => emit(GroupActionError(core.failureToMessage(failure))),
      (group) => emit(GroupActionSuccess(group)),
    );
  }
}
