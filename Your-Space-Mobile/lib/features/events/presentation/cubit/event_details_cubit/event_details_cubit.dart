import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_guest_repository.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_repository.dart';

import '../failure_messages.dart';
import 'event_details_state.dart';

@injectable
class EventDetailsCubit extends Cubit<EventDetailsState> {
  final EventRepository _eventRepository;
  final EventGuestRepository _eventGuestRepository;
  final DataRefreshBus _dataRefreshBus;
  late final StreamSubscription<DataScope> _refreshSubscription;

  EventDetailsCubit(this._eventRepository, this._eventGuestRepository, this._dataRefreshBus)
      : super(const EventDetailsInitial()) {
    _refreshSubscription = _dataRefreshBus.stream.listen((scope) {
      if (scope == DataScope.events || scope == DataScope.eventGuests) refresh();
    });
  }

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

  /// Re-fetches this same event (+ guest progress) without a `Loading`
  /// flash — triggered by [DataRefreshBus] when the event was edited via
  /// `EventForm`, or its guest roster/status changed via `EventGuestsScreen`
  /// / `AddGuestsScreen`, and the user popped back here. Keeps the
  /// last-good details on screen on a background failure.
  Future<void> refresh() async {
    final current = state;
    if (current is! EventDetailsSuccess) return;
    final eventId = current.event.id;
    final eventResult = await _eventRepository.getEventById(eventId);
    await eventResult.fold(
      (_) async {},
      (event) async {
        final progressResult = await _eventGuestRepository.getProgress(eventId);
        progressResult.fold(
          (_) {},
          (progress) => emit(EventDetailsSuccess(event: event, progress: progress)),
        );
      },
    );
  }

  @override
  Future<void> close() {
    _refreshSubscription.cancel();
    return super.close();
  }
}
