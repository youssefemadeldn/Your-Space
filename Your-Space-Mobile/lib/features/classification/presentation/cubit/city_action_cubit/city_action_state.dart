import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/entities/city.dart';

sealed class CityActionState extends Equatable {
  const CityActionState();
  @override
  List<Object?> get props => const [];
}

final class CityActionInitial extends CityActionState {
  const CityActionInitial();
}

final class CityActionSubmitting extends CityActionState {
  const CityActionSubmitting();
}

final class CityActionSaveSuccess extends CityActionState {
  final City city;
  const CityActionSaveSuccess(this.city);
  @override
  List<Object?> get props => [city];
}

final class CityActionDeleteSuccess extends CityActionState {
  const CityActionDeleteSuccess();
}

final class CityActionError extends CityActionState {
  final String message;
  const CityActionError(this.message);
  @override
  List<Object?> get props => [message];
}
