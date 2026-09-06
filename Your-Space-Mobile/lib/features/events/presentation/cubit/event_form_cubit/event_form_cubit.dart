import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_repository.dart';

import '../failure_messages.dart';
import 'event_form_state.dart';

/// Single cubit for both load+submit — mirrors `PersonFormCubit`/
/// `ResetPasswordCubit`'s precedent for a full-navigation form with no
/// simultaneous list.
@injectable
class EventFormCubit extends Cubit<EventFormState> {
  final EventRepository _eventRepository;
  final DataRefreshBus _dataRefreshBus;

  EventFormCubit(this._eventRepository, this._dataRefreshBus) : super(const EventFormInitial());

  Future<void> initialize(int? eventId) async {
    if (eventId == null) {
      emit(const EventFormReady());
      return;
    }
    emit(const EventFormLoading());
    final result = await _eventRepository.getEventById(eventId);
    result.fold(
      (failure) => emit(EventFormError(failureToMessage(failure))),
      (event) => emit(EventFormReady(event: event)),
    );
  }

  Future<void> submit({
    int? eventId,
    required String name,
    String? nameAr,
    DateTime? eventDate,
    String? notes,
  }) async {
    emit(const EventFormSubmitting());
    final result = eventId == null
        ? await _eventRepository.createEvent(name: name, nameAr: nameAr, eventDate: eventDate, notes: notes)
        : await _eventRepository.updateEvent(
            id: eventId,
            name: name,
            nameAr: nameAr,
            eventDate: eventDate,
            notes: notes,
          );
    result.fold(
      (failure) => emit(EventFormError(failureToMessage(failure))),
      (event) {
        _dataRefreshBus.notify(DataScope.events);
        emit(EventFormSuccess(event));
      },
    );
  }
}
