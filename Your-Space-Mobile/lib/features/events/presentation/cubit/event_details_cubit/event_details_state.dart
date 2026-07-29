import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/mock/entities/event.dart';
import 'package:your_space_mobile/core/mock/entities/event_guest_progress_summary.dart';

sealed class EventDetailsState extends Equatable {
  const EventDetailsState();
  @override
  List<Object?> get props => const [];
}

final class EventDetailsInitial extends EventDetailsState {
  const EventDetailsInitial();
}

final class EventDetailsLoading extends EventDetailsState {
  const EventDetailsLoading();
}

final class EventDetailsSuccess extends EventDetailsState {
  final Event event;
  final EventGuestProgressSummary progress;

  const EventDetailsSuccess({required this.event, required this.progress});

  @override
  List<Object?> get props => [event, progress];
}

final class EventDetailsError extends EventDetailsState {
  final String message;
  const EventDetailsError(this.message);
  @override
  List<Object?> get props => [message];
}
