import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/mock/mock_data_store.dart';

import 'event_details_state.dart';

@injectable
class EventDetailsCubit extends Cubit<EventDetailsState> {
  final MockDataStore _store;

  EventDetailsCubit(this._store) : super(const EventDetailsInitial());

  Future<void> loadDetails(int eventId) async {
    emit(const EventDetailsLoading());
    await Future.delayed(_store.simulatedLatency);
    final event = _store.eventById(eventId);
    if (event == null) {
      emit(EventDetailsError('events.details.notFound'.tr()));
      return;
    }
    emit(EventDetailsSuccess(event: event, progress: _store.eventProgress(eventId)));
  }
}
