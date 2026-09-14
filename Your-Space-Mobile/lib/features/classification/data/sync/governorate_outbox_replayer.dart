import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/outbox_replayer.dart';
import '../datasources/base_governorate_data_source.dart';
import '../datasources/governorate_local_data_source_impl.dart';
import '../models/create_governorate_request.dart';

/// `SyncService`'s entityType: 'governorate' strategy — mirrors
/// `GroupOutboxReplayer`. The only place `BaseGovernorateDataSource`'s
/// `createGovernorate` is called from now that Tier 2 has replaced
/// `GovernorateRepositoryImpl`'s direct remote call with the outbox
/// (row 8.3). See `PersonOutboxReplayer`'s doc comment for why this
/// class-level `@Named` tag exists (distinct from the constructor's own
/// `@Named` params) — it avoids colliding with the other entities'
/// registrations under injectable's duplicate-registration check.
@Named('governorate')
@LazySingleton(as: OutboxReplayer)
class GovernorateOutboxReplayer implements OutboxReplayer {
  final BaseGovernorateDataSource _remote;
  final GovernorateLocalDataSourceImpl _local;

  GovernorateOutboxReplayer(@Named('remote') this._remote, @Named('local') this._local);

  @override
  String get entityType => 'governorate';

  @override
  Future<Either<Failure, Object?>> replay(OutboxTableData row) async {
    final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    switch (row.operation) {
      case 'create':
        final result = await _remote.createGovernorate(_createRequestFrom(payload));
        return result.fold<Future<Either<Failure, Object?>>>(
          (failure) async => Left(failure),
          (response) async {
            final realGovernorate = response.toEntity();
            await _local.reconcileCreatedGovernorate(
              tempId: row.entityId,
              realGovernorate: realGovernorate,
              replayedOutboxRowId: row.id,
            );
            return Right(realGovernorate);
          },
        );
      default:
        // No 'update'/'delete' exists in Governorate's mobile UI (no
        // management screen — see `BaseGovernorateRepository`'s doc
        // comment) — fail loudly rather than silently drop, so a future
        // feature can't accidentally queue an unhandled operation without
        // noticing.
        return Left(
          UnexpectedFailure(message: 'Unsupported governorate outbox operation: ${row.operation}'),
        );
    }
  }

  CreateGovernorateRequest _createRequestFrom(Map<String, dynamic> json) =>
      CreateGovernorateRequest(name: json['name'] as String, nameAr: json['nameAr'] as String?);
}
