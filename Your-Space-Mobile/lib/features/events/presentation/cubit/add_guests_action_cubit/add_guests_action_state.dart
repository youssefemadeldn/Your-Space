import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/features/events/domain/entities/bulk_add_guests_result.dart';

sealed class AddGuestsActionState extends Equatable {
  const AddGuestsActionState();
  @override
  List<Object?> get props => const [];
}

final class AddGuestsActionInitial extends AddGuestsActionState {
  const AddGuestsActionInitial();
}

final class AddGuestsActionSubmitting extends AddGuestsActionState {
  const AddGuestsActionSubmitting();
}

final class AddGuestsActionSuccess extends AddGuestsActionState {
  final BulkAddGuestsResult result;
  const AddGuestsActionSuccess(this.result);
  @override
  List<Object?> get props => [result];
}

final class AddGuestsActionError extends AddGuestsActionState {
  final String message;
  const AddGuestsActionError(this.message);
  @override
  List<Object?> get props => [message];
}
