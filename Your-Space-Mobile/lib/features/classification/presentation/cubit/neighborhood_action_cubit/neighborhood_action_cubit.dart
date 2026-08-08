import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/classification/domain/repositories/base_neighborhood_repository.dart';

import 'neighborhood_action_state.dart';

@injectable
class NeighborhoodActionCubit extends Cubit<NeighborhoodActionState> {
  final NeighborhoodRepository _neighborhoodRepository;
  final DataRefreshBus _dataRefreshBus;

  NeighborhoodActionCubit(this._neighborhoodRepository, this._dataRefreshBus)
      : super(const NeighborhoodActionInitial());

  Future<void> createNeighborhood({required int cityId, required String name, String? nameAr}) async {
    emit(const NeighborhoodActionSubmitting());
    final result = await _neighborhoodRepository.createNeighborhood(cityId: cityId, name: name, nameAr: nameAr);
    result.fold(
      (failure) => emit(NeighborhoodActionError(core.failureToMessage(failure))),
      (neighborhood) {
        _dataRefreshBus.notify(DataScope.classification);
        emit(NeighborhoodActionSaveSuccess(neighborhood));
      },
    );
  }

  Future<void> updateNeighborhood({
    required int cityId,
    required int id,
    required String name,
    String? nameAr,
  }) async {
    emit(const NeighborhoodActionSubmitting());
    final result =
        await _neighborhoodRepository.updateNeighborhood(cityId: cityId, id: id, name: name, nameAr: nameAr);
    result.fold(
      (failure) => emit(NeighborhoodActionError(core.failureToMessage(failure))),
      (neighborhood) {
        _dataRefreshBus.notify(DataScope.classification);
        emit(NeighborhoodActionSaveSuccess(neighborhood));
      },
    );
  }

  Future<void> deleteNeighborhood({required int cityId, required int id}) async {
    emit(const NeighborhoodActionSubmitting());
    final result = await _neighborhoodRepository.deleteNeighborhood(cityId: cityId, id: id);
    result.fold(
      (failure) => emit(NeighborhoodActionError(core.failureToMessage(failure))),
      (_) {
        _dataRefreshBus.notify(DataScope.classification);
        emit(const NeighborhoodActionDeleteSuccess());
      },
    );
  }
}
