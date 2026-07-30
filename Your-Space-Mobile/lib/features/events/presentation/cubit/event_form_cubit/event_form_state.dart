import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/features/events/domain/entities/event.dart';

sealed class EventFormState extends Equatable {
  const EventFormState();
  @override
  List<Object?> get props => const [];
}

final class EventFormInitial extends EventFormState {
  const EventFormInitial();
}

final class EventFormLoading extends EventFormState {
  const EventFormLoading();
}

/// [event] is null in create mode, populated in edit mode for pre-fill.
final class EventFormReady extends EventFormState {
  final Event? event;
  const EventFormReady({this.event});
  @override
  List<Object?> get props => [event];
}

final class EventFormSubmitting extends EventFormState {
  const EventFormSubmitting();
}

final class EventFormSuccess extends EventFormState {
  final Event event;
  const EventFormSuccess(this.event);
  @override
  List<Object?> get props => [event];
}

final class EventFormError extends EventFormState {
  final String message;
  const EventFormError(this.message);
  @override
  List<Object?> get props => [message];
}
