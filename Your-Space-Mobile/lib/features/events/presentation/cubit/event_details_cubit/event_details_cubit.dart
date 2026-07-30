import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/features/events/domain/repositories/base_event_guest_repository.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_repository.dart';

import '../failure_messages.dart';
import 'event_details_state.dart';

@injectable
class EventDetailsCubit extends Cubit<EventDetailsState> {
  final EventRepository _eventRepository;
  final EventGuestRepository _eventGuestRepository;

  EventDetailsCubit(this._eventRepository, this._eventGuestRepository)
      : super(const EventDetailsInitial());

  Future<void> loadDetails(int eventId) async {
    emit(const EventDetailsLoading());
    final eventResult = await _eventRepository.getEventById(eventId);
    await eventResult.fold(
      (failure) async => emit(EventDetailsError(failureToMessage(failure))),
      (event) async {
        final progressResult = await _eventGuestRepository.getProgress(eventId);
        progressResult.fold(
          (failure) => emit(EventDetailsError(failureToMessage(failure))),
          (progress) => emit(EventDetailsSuccess(event: event, progress: progress)),
        );
      },
    );
  }
}
