import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/mock/entities/group.dart';

sealed class GroupActionState extends Equatable {
  const GroupActionState();
  @override
  List<Object?> get props => const [];
}

final class GroupActionInitial extends GroupActionState {
  const GroupActionInitial();
}

final class GroupActionSubmitting extends GroupActionState {
  const GroupActionSubmitting();
}

final class GroupActionSuccess extends GroupActionState {
  final Group group;
  const GroupActionSuccess(this.group);
  @override
  List<Object?> get props => [group];
}

final class GroupActionError extends GroupActionState {
  final String message;
  const GroupActionError(this.message);
  @override
  List<Object?> get props => [message];
}
