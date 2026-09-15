import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/outbox_replayer.dart';
import '../datasources/base_neighborhood_data_source.dart';
import '../datasources/neighborhood_local_data_source_impl.dart';
import '../models/create_neighborhood_request.dart';
import '../models/update_neighborhood_request.dart';

/// `SyncService`'s entityType: 'neighborhood' strategy — mirrors
/// `CityOutboxReplayer`, including its real `'delete'` branch (City already
/// designed this shape fresh at row 8.9; nothing new to design here).
@Named('neighborhood')
@LazySingleton(as: OutboxReplayer)
class NeighborhoodOutboxReplayer implements OutboxReplayer {
  final BaseNeighborhoodDataSource _remote;
  final NeighborhoodLocalDataSourceImpl _local;

  NeighborhoodOutboxReplayer(@Named('remote') this._remote, @Named('local') this._local);

  @override
  String get entityType => 'neighborhood';

  @override
  Future<Either<Failure, Object?>> replay(OutboxTableData row) async {
    final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    final cityId = payload['cityId'] as int;
    switch (row.operation) {
      case 'create':
        final result = await _remote.createNeighborhood(cityId, _createRequestFrom(payload));
        return result.fold<Future<Either<Failure, Object?>>>(
          (failure) async => Left(failure),
          (response) async {
            final realNeighborhood = response.toEntity();
            await _local.reconcileCreatedNeighborhood(
              tempId: row.entityId,
              realNeighborhood: realNeighborhood,
              replayedOutboxRowId: row.id,
            );
            return Right(realNeighborhood);
          },
        );
      case 'update':
        final result = await _remote.updateNeighborhood(cityId, row.entityId, _updateRequestFrom(payload));
        return result.fold<Future<Either<Failure, Object?>>>(
          (failure) async => Left(failure),
          (response) async {
            final neighborhood = response.toEntity();
            await _local.confirmSyncedNeighborhood(neighborhood, replayedOutboxRowId: row.id);
            return Right(neighborhood);
          },
        );
      case 'delete':
        final result = await _remote.deleteNeighborhood(cityId, row.entityId);
        return result.fold<Future<Either<Failure, Object?>>>(
          (failure) async => Left(failure),
          (_) async {
            await _local.confirmDeletedNeighborhood(row.entityId, replayedOutboxRowId: row.id);
            return const Right(null);
          },
        );
      default:
        return Left(UnexpectedFailure(message: 'Unsupported neighborhood outbox operation: ${row.operation}'));
    }
  }

  CreateNeighborhoodRequest _createRequestFrom(Map<String, dynamic> json) =>
      CreateNeighborhoodRequest(name: json['name'] as String, nameAr: json['nameAr'] as String?);

  UpdateNeighborhoodRequest _updateRequestFrom(Map<String, dynamic> json) =>
      UpdateNeighborhoodRequest(name: json['name'] as String, nameAr: json['nameAr'] as String?);
}
