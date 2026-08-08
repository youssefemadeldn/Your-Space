import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/entities/subgroup.dart';

sealed class SubGroupActionState extends Equatable {
  const SubGroupActionState();
  @override
  List<Object?> get props => const [];
}

final class SubGroupActionInitial extends SubGroupActionState {
  const SubGroupActionInitial();
}

final class SubGroupActionSubmitting extends SubGroupActionState {
  const SubGroupActionSubmitting();
}

final class SubGroupActionSaveSuccess extends SubGroupActionState {
  final SubGroup subGroup;
  const SubGroupActionSaveSuccess(this.subGroup);
  @override
  List<Object?> get props => [subGroup];
}

final class SubGroupActionDeleteSuccess extends SubGroupActionState {
  const SubGroupActionDeleteSuccess();
}

final class SubGroupActionError extends SubGroupActionState {
  final String message;
  const SubGroupActionError(this.message);
  @override
  List<Object?> get props => [message];
}
