import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/neighborhood.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/sync_service.dart';
import '../../domain/repositories/base_neighborhood_repository.dart';
import '../datasources/base_neighborhood_data_source.dart';
import '../datasources/neighborhood_local_data_source_impl.dart';
import '../models/create_neighborhood_request.dart';
import '../models/update_neighborhood_request.dart';

@LazySingleton(as: NeighborhoodRepository)
class NeighborhoodRepositoryImpl implements NeighborhoodRepository {
  final BaseNeighborhoodDataSource _remote;
  final NeighborhoodLocalDataSourceImpl _local;
  final SyncService _syncService;

  NeighborhoodRepositoryImpl(
    @Named('remote') this._remote,
    @Named('local') this._local,
    this._syncService,
  );

  @override
  Future<Either<Failure, PaginatedResult<Neighborhood>>> getNeighborhoods({
    required int cityId,
    String? search,
    required int pageIndex,
    required int pageSize,
  }) async {
    final result = await _remote.getNeighborhoods(
      cityId: cityId,
      search: search,
      pageIndex: pageIndex,
      pageSize: pageSize,
    );
    return result.fold(Left.new, (response) => Right(response.toResult((r) => r.toEntity())));
  }

  @override
  Stream<List<Neighborhood>> watchNeighborhoods({required int cityId, String? search, required int limit}) =>
      _local.watchNeighborhoods(cityId: cityId, search: search, limit: limit);

  @override
  Future<int> countNeighborhoods({required int cityId, String? search}) =>
      _local.countNeighborhoods(cityId: cityId, search: search);

  int _newTempNeighborhoodId() => -DateTime.now().microsecondsSinceEpoch;

  /// Builds the [Neighborhood] draft + JSON-encoded create payload (cityId
  /// included alongside the request body — `CreateNeighborhoodRequest.toJson()`
  /// omits it since it's normally routed, but `NeighborhoodOutboxReplayer`
  /// needs it to call `BaseNeighborhoodDataSource.createNeighborhood(cityId,
  /// ...)`) and queues both via the outbox. Shared by [createNeighborhood]
  /// and [createNeighborhoodAndSync].
  Future<(Neighborhood, int)> _queueCreate({required int cityId, required String name, String? nameAr}) async {
    final neighborhood = Neighborhood(id: _newTempNeighborhoodId(), cityId: cityId, name: name, nameAr: nameAr);
    final payloadJson = jsonEncode({
      'cityId': cityId,
      ...CreateNeighborhoodRequest(name: name, nameAr: nameAr).toJson(),
    });
    final rowId = await _local.queueNeighborhoodMutation(
      neighborhood: neighborhood,
      operation: 'create',
      payloadJson: payloadJson,
    );
    return (neighborhood, rowId);
  }

  @override
  Future<Either<Failure, Neighborhood>> createNeighborhood({
    required int cityId,
    required String name,
    String? nameAr,
  }) async {
    final (neighborhood, _) = await _queueCreate(cityId: cityId, name: name, nameAr: nameAr);
    return Right(neighborhood);
  }

  @override
  Future<Either<Failure, Neighborhood>> createNeighborhoodAndSync({
    required int cityId,
    required String name,
    String? nameAr,
  }) async {
    final (neighborhood, rowId) = await _queueCreate(cityId: cityId, name: name, nameAr: nameAr);
    final result = await _syncService.replayRow(rowId);
    return result.fold(Left.new, (payload) => Right(payload as Neighborhood? ?? neighborhood));
  }

  @override
  Future<Either<Failure, Neighborhood>> updateNeighborhood({
    required int cityId,
    required int id,
    required String name,
    String? nameAr,
  }) async {
    final neighborhood = Neighborhood(id: id, cityId: cityId, name: name, nameAr: nameAr);
    final payloadJson = jsonEncode({
      'cityId': cityId,
      ...UpdateNeighborhoodRequest(name: name, nameAr: nameAr).toJson(),
    });
    await _local.queueNeighborhoodMutation(neighborhood: neighborhood, operation: 'update', payloadJson: payloadJson);
    return Right(neighborhood);
  }

  @override
  Future<Either<Failure, Unit>> deleteNeighborhood({required int cityId, required int id}) async {
    await _local.queueDeletedNeighborhood(id, payloadJson: jsonEncode({'cityId': cityId}));
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> refreshNeighborhoods() async {
    const pageSize = 200;
    // Defensive cap against a pathological `hasMore`/`totalPages` loop — this
    // data shape is meant to be small (a user's own custom neighborhoods),
    // never expected to trip.
    const maxPages = 50;
    final all = <Neighborhood>[];
    for (var pageIndex = 1; pageIndex <= maxPages; pageIndex++) {
      final result = await _remote.getAllMineNeighborhoods(pageIndex: pageIndex, pageSize: pageSize);
      if (result.isLeft()) {
        return result.fold(Left.new, (_) => throw StateError('unreachable'));
      }
      final page = result.getOrElse(() => throw StateError('unreachable'));
      all.addAll(page.items.map((r) => r.toEntity()));
      if (pageIndex >= page.totalPages) break;
    }
    await _local.applyNeighborhoodsSnapshot(all);
    return const Right(unit);
  }
}
