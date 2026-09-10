import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/classification/domain/repositories/base_city_repository.dart';

import 'city_action_state.dart';

@injectable
class CityActionCubit extends Cubit<CityActionState> {
  final CityRepository _cityRepository;
  final DataRefreshBus _dataRefreshBus;

  CityActionCubit(this._cityRepository, this._dataRefreshBus) : super(const CityActionInitial());

  Future<void> createCity({required int governorateId, required String name, String? nameAr}) async {
    emit(const CityActionSubmitting());
    final result = await _cityRepository.createCity(governorateId: governorateId, name: name, nameAr: nameAr);
    result.fold(
      (failure) => emit(CityActionError(core.failureToMessage(failure))),
      (city) {
        _dataRefreshBus.notify(DataScope.classification);
        emit(CityActionSaveSuccess(city));
      },
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
      (city) {
        _dataRefreshBus.notify(DataScope.classification);
        emit(CityActionSaveSuccess(city));
      },
    );
  }

  Future<void> deleteCity({required int governorateId, required int id}) async {
    emit(const CityActionSubmitting());
    final result = await _cityRepository.deleteCity(governorateId: governorateId, id: id);
    result.fold(
      (failure) => emit(CityActionError(core.failureToMessage(failure))),
      (_) {
        _dataRefreshBus.notify(DataScope.classification);
        emit(const CityActionDeleteSuccess());
      },
    );
  }
}
