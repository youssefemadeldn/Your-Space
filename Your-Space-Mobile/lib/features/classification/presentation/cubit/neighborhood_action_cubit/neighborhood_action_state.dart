import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/entities/neighborhood.dart';

sealed class NeighborhoodActionState extends Equatable {
  const NeighborhoodActionState();
  @override
  List<Object?> get props => const [];
}

final class NeighborhoodActionInitial extends NeighborhoodActionState {
  const NeighborhoodActionInitial();
}

final class NeighborhoodActionSubmitting extends NeighborhoodActionState {
  const NeighborhoodActionSubmitting();
}

final class NeighborhoodActionSaveSuccess extends NeighborhoodActionState {
  final Neighborhood neighborhood;
  const NeighborhoodActionSaveSuccess(this.neighborhood);
  @override
  List<Object?> get props => [neighborhood];
}

final class NeighborhoodActionDeleteSuccess extends NeighborhoodActionState {
  const NeighborhoodActionDeleteSuccess();
}

final class NeighborhoodActionError extends NeighborhoodActionState {
  final String message;
  const NeighborhoodActionError(this.message);
  @override
  List<Object?> get props => [message];
}
