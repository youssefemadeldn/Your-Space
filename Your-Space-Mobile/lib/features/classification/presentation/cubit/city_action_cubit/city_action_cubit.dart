import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/classification/domain/repositories/base_city_repository.dart';

import 'city_action_state.dart';

/// No `DataRefreshBus` notification on success (retired in row 8.9, mirrors
/// `GroupActionCubit`'s own 7.3 retirement): `CityRepositoryImpl`'s
/// create/update/delete already write straight into drift via the outbox,
/// so every open `watchCities` stream — including `CityListCubit`'s — sees
/// the change directly (design doc §7).
@injectable
class CityActionCubit extends Cubit<CityActionState> {
  final CityRepository _cityRepository;

  CityActionCubit(this._cityRepository) : super(const CityActionInitial());

  Future<void> createCity({required int governorateId, required String name, String? nameAr}) async {
    emit(const CityActionSubmitting());
    final result = await _cityRepository.createCity(governorateId: governorateId, name: name, nameAr: nameAr);
    result.fold(
      (failure) => emit(CityActionError(core.failureToMessage(failure))),
      (city) => emit(CityActionSaveSuccess(city)),
    );
  }

  Future<void> updateCity({
    required int governorateId,
    required int id,
    required String name,
    String? nameAr,
  }) async {
    emit(const CityActionSubmitting());
    final result =
        await _cityRepository.updateCity(governorateId: governorateId, id: id, name: name, nameAr: nameAr);
    result.fold(
      (failure) => emit(CityActionError(core.failureToMessage(failure))),
      (city) => emit(CityActionSaveSuccess(city)),
    );
  }

  Future<void> deleteCity({required int governorateId, required int id}) async {
    emit(const CityActionSubmitting());
    final result = await _cityRepository.deleteCity(governorateId: governorateId, id: id);
    result.fold(
      (failure) => emit(CityActionError(core.failureToMessage(failure))),
      (_) => emit(const CityActionDeleteSuccess()),
    );
  }
}
