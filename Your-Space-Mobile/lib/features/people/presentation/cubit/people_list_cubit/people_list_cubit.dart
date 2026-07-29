import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/mock/mock_data_store.dart';

import 'people_list_state.dart';

@injectable
class PeopleListCubit extends Cubit<PeopleListState> {
  final MockDataStore _store;

  PeopleListCubit(this._store) : super(const PeopleListInitial());

  Future<void> load() async {
    emit(const PeopleListLoading());
    await Future.delayed(_store.simulatedLatency);
    emit(PeopleListSuccess(people: _store.people(), groups: _store.groups()));
  }

  void search(String query) {
    final current = state;
    if (current is! PeopleListSuccess) return;
    emit(PeopleListSuccess(
      people: _store.people(groupId: current.selectedGroupId, search: query),
      groups: current.groups,
      selectedGroupId: current.selectedGroupId,
    ));
  }

  void filterByGroup(int? groupId) {
    final current = state;
    if (current is! PeopleListSuccess) return;
    emit(PeopleListSuccess(
      people: _store.people(groupId: groupId),
      groups: current.groups,
      selectedGroupId: groupId,
    ));
  }
}
