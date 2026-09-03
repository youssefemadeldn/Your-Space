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
  // Which specific action is in flight — never both, so each consumer can tell whether
  // *its own* row/button is the one submitting instead of reacting to any submission at all.
  // addGroup sets groupId; addPersons sets personIds.
  final int? groupId;
  final List<int>? personIds;

  const AddGuestsActionSubmitting({this.groupId, this.personIds});

  @override
  List<Object?> get props => [groupId, personIds];
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
