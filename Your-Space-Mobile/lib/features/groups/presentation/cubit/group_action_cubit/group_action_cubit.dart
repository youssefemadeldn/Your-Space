import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/mock/mock_data_store.dart';

import 'group_action_state.dart';

@injectable
class GroupActionCubit extends Cubit<GroupActionState> {
  final MockDataStore _store;

  GroupActionCubit(this._store) : super(const GroupActionInitial());

  Future<void> createGroup({required String name, String? nameAr}) async {
    emit(const GroupActionSubmitting());
    await Future.delayed(_store.simulatedLatency);
    emit(GroupActionSuccess(_store.createGroup(name: name, nameAr: nameAr)));
  }

  Future<void> updateGroup({required int id, required String name, String? nameAr}) async {
    emit(const GroupActionSubmitting());
    await Future.delayed(_store.simulatedLatency);
    emit(GroupActionSuccess(_store.updateGroup(id: id, name: name, nameAr: nameAr)));
  }
}
