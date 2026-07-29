import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/mock/mock_data_store.dart';

import 'event_form_state.dart';

/// Single cubit for both load+submit — mirrors `PersonFormCubit`/
/// `ResetPasswordCubit`'s precedent for a full-navigation form with no
/// simultaneous list.
@injectable
class EventFormCubit extends Cubit<EventFormState> {
  final MockDataStore _store;

  EventFormCubit(this._store) : super(const EventFormInitial());

  void initialize(int? eventId) {
    final event = eventId == null ? null : _store.eventById(eventId);
    emit(EventFormReady(event: event));
  }

  Future<void> submit({
    int? eventId,
    required String name,
    String? nameAr,
    DateTime? eventDate,
    String? notes,
  }) async {
    emit(const EventFormSubmitting());
    await Future.delayed(_store.simulatedLatency);
    final event = eventId == null
        ? _store.createEvent(name: name, nameAr: nameAr, eventDate: eventDate, notes: notes)
        : _store.updateEvent(id: eventId, name: name, nameAr: nameAr, eventDate: eventDate, notes: notes);
    emit(EventFormSuccess(event));
  }
}
