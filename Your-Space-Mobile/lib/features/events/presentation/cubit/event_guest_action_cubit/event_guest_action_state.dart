import 'package:equatable/equatable.dart';

sealed class EventGuestActionState extends Equatable {
  const EventGuestActionState();
  @override
  List<Object?> get props => const [];
}

final class EventGuestActionInitial extends EventGuestActionState {
  const EventGuestActionInitial();
}

final class EventGuestActionSubmitting extends EventGuestActionState {
  const EventGuestActionSubmitting();
}

final class EventGuestActionSuccess extends EventGuestActionState {
  const EventGuestActionSuccess();
}

final class EventGuestActionError extends EventGuestActionState {
  final String message;
  const EventGuestActionError(this.message);
  @override
  List<Object?> get props => [message];
}
