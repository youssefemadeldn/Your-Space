import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/mock/mock_data_store.dart';

import 'events_list_state.dart';

@injectable
class EventsListCubit extends Cubit<EventsListState> {
  final MockDataStore _store;

  EventsListCubit(this._store) : super(const EventsListInitial());

  Future<void> load() async {
    emit(const EventsListLoading());
    await Future.delayed(_store.simulatedLatency);
    emit(EventsListSuccess(_store.events()));
  }

  void search(String query) {
    if (state is! EventsListSuccess) return;
    emit(EventsListSuccess(_store.events(search: query)));
  }
}
