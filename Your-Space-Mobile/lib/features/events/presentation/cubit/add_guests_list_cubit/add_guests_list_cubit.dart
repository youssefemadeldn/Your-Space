import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/mock/mock_data_store.dart';

import 'add_guests_list_state.dart';

@injectable
class AddGuestsListCubit extends Cubit<AddGuestsListState> {
  final MockDataStore _store;

  AddGuestsListCubit(this._store) : super(const AddGuestsListInitial());

  Future<void> load(int eventId) async {
    emit(const AddGuestsListLoading());
    await Future.delayed(_store.simulatedLatency);
    final existingIds = _store.eventGuests(eventId).map((g) => g.personId).toSet();
    final available = _store.people().where((p) => !existingIds.contains(p.id)).toList();
    emit(AddGuestsListSuccess(availablePeople: available, groups: _store.groups()));
  }
}
