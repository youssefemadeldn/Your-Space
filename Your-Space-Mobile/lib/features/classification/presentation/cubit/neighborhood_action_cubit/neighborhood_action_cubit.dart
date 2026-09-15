import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/classification/domain/repositories/base_neighborhood_repository.dart';

import 'neighborhood_action_state.dart';

/// No `DataRefreshBus` dependency (row 8.20) — the repository's transitional
/// local-upsert-on-success write path already reaches every open
/// `watchNeighborhoods` stream directly, same reasoning as
/// `CityActionCubit`/`SubGroupActionCubit`'s own `DataScope.classification`
/// removal.
@injectable
class NeighborhoodActionCubit extends Cubit<NeighborhoodActionState> {
  final NeighborhoodRepository _neighborhoodRepository;

  NeighborhoodActionCubit(this._neighborhoodRepository) : super(const NeighborhoodActionInitial());

  Future<void> createNeighborhood({required int cityId, required String name, String? nameAr}) async {
    emit(const NeighborhoodActionSubmitting());
    final result = await _neighborhoodRepository.createNeighborhood(cityId: cityId, name: name, nameAr: nameAr);
    result.fold(
      (failure) => emit(NeighborhoodActionError(core.failureToMessage(failure))),
      (neighborhood) => emit(NeighborhoodActionSaveSuccess(neighborhood)),
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
      (neighborhood) => emit(NeighborhoodActionSaveSuccess(neighborhood)),
    );
  }

  Future<void> deleteNeighborhood({required int cityId, required int id}) async {
    emit(const NeighborhoodActionSubmitting());
    final result = await _neighborhoodRepository.deleteNeighborhood(cityId: cityId, id: id);
    result.fold(
      (failure) => emit(NeighborhoodActionError(core.failureToMessage(failure))),
      (_) => emit(const NeighborhoodActionDeleteSuccess()),
    );
  }
}
