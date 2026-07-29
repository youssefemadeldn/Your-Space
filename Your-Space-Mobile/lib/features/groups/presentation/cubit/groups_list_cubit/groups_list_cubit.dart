import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/mock/mock_data_store.dart';

import 'groups_list_state.dart';

@injectable
class GroupsListCubit extends Cubit<GroupsListState> {
  final MockDataStore _store;

  GroupsListCubit(this._store) : super(const GroupsListInitial());

  Future<void> load() async {
    emit(const GroupsListLoading());
    await Future.delayed(_store.simulatedLatency);
    emit(GroupsListSuccess(_store.groups()));
  }

  void search(String query) {
    if (state is! GroupsListSuccess) return;
    emit(GroupsListSuccess(_store.groups(search: query)));
  }
}
