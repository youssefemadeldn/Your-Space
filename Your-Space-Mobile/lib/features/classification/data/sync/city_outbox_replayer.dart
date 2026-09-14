import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/outbox_replayer.dart';
import '../datasources/base_city_data_source.dart';
import '../datasources/city_local_data_source_impl.dart';
import '../models/create_city_request.dart';
import '../models/update_city_request.dart';

/// `SyncService`'s entityType: 'city' strategy — mirrors
/// `GroupOutboxReplayer`, but City is Row 8's first entity with a real
/// `'delete'` branch (Governorate is create-only; Group and Person's own
/// `'delete'` branches are still the unimplemented "fails loudly" default —
/// there was no existing implementation to copy). See `PersonOutboxReplayer`'s
/// doc comment for why this class-level `@Named` tag exists.
@Named('city')
@LazySingleton(as: OutboxReplayer)
class CityOutboxReplayer implements OutboxReplayer {
  final BaseCityDataSource _remote;
  final CityLocalDataSourceImpl _local;

  CityOutboxReplayer(@Named('remote') this._remote, @Named('local') this._local);

  @override
  String get entityType => 'city';

  @override
  Future<Either<Failure, Object?>> replay(OutboxTableData row) async {
    final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    final governorateId = payload['governorateId'] as int;
    switch (row.operation) {
      case 'create':
        final result = await _remote.createCity(governorateId, _createRequestFrom(payload));
        return result.fold<Future<Either<Failure, Object?>>>(
          (failure) async => Left(failure),
          (response) async {
            final realCity = response.toEntity();
            await _local.reconcileCreatedCity(
              tempId: row.entityId,
              realCity: realCity,
              replayedOutboxRowId: row.id,
            );
            return Right(realCity);
          },
        );
      case 'update':
        final result = await _remote.updateCity(governorateId, row.entityId, _updateRequestFrom(payload));
        return result.fold<Future<Either<Failure, Object?>>>(
          (failure) async => Left(failure),
          (response) async {
            final city = response.toEntity();
            await _local.confirmSyncedCity(city, replayedOutboxRowId: row.id);
            return Right(city);
          },
        );
      case 'delete':
        final result = await _remote.deleteCity(governorateId, row.entityId);
        return result.fold<Future<Either<Failure, Object?>>>(
          (failure) async => Left(failure),
          (_) async {
            await _local.confirmDeletedCity(row.entityId, replayedOutboxRowId: row.id);
            return const Right(null);
          },
        );
      default:
        return Left(UnexpectedFailure(message: 'Unsupported city outbox operation: ${row.operation}'));
    }
  }

  CreateCityRequest _createRequestFrom(Map<String, dynamic> json) =>
      CreateCityRequest(name: json['name'] as String, nameAr: json['nameAr'] as String?);

  UpdateCityRequest _updateRequestFrom(Map<String, dynamic> json) =>
      UpdateCityRequest(name: json['name'] as String, nameAr: json['nameAr'] as String?);
}
