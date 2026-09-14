import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/outbox_replayer.dart';
import '../datasources/base_person_data_source.dart';
import '../datasources/person_local_data_source_impl.dart';
import '../models/create_person_request.dart';
import '../models/update_person_request.dart';

/// `SyncService`'s entityType: 'person' strategy — the only place
/// [BasePersonDataSource]'s create/update methods are called from now that
/// Tier 2 has replaced `PersonRepositoryImpl`'s direct remote calls with the
/// outbox (design doc §5: "unchanged — Tier 2 doesn't touch ApiManager/
/// AuthInterceptor/Failure mapping").
/// The `@Named` tag here (distinct from the `@Named('remote')`/`@Named('local')`
/// on this class's own constructor params below) exists solely so this
/// registration and `GroupOutboxReplayer`'s don't collide under injectable's
/// duplicate-registration check, which only allows one *unnamed* binding per
/// interface — `RegisterModule.outboxReplayers` collects every tagged
/// `OutboxReplayer` back into the `List<OutboxReplayer>` `SyncService`
/// actually wants, via `GetIt.getAll`, which ignores instance names.
@Named('person')
@LazySingleton(as: OutboxReplayer)
class PersonOutboxReplayer implements OutboxReplayer {
  final BasePersonDataSource _remote;
  final PersonLocalDataSourceImpl _local;

  PersonOutboxReplayer(@Named('remote') this._remote, @Named('local') this._local);

  @override
  String get entityType => 'person';

  @override
  Future<Either<Failure, Object?>> replay(OutboxTableData row) async {
    final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    switch (row.operation) {
      case 'create':
        final result = await _remote.createPerson(_createRequestFrom(payload));
        return result.fold<Future<Either<Failure, Object?>>>(
          (failure) async => Left(failure),
          (response) async {
            final realPerson = response.toEntity();
            await _local.reconcileCreatedPerson(
              tempId: row.entityId,
              realPerson: realPerson,
              replayedOutboxRowId: row.id,
            );
            return Right(realPerson);
          },
        );
      case 'update':
        final result = await _remote.updatePerson(_updateRequestFrom(payload));
        return result.fold<Future<Either<Failure, Object?>>>(
          (failure) async => Left(failure),
          (response) async {
            final person = response.toEntity();
            await _local.confirmSyncedPerson(person, replayedOutboxRowId: row.id);
            return Right(person);
          },
        );
      default:
        // No 'delete' exists in People yet — fail loudly rather than
        // silently drop, so a future delete feature can't accidentally
        // queue an unhandled operation without noticing.
        return Left(UnexpectedFailure(message: 'Unsupported person outbox operation: ${row.operation}'));
    }
  }

  CreatePersonRequest _createRequestFrom(Map<String, dynamic> json) => CreatePersonRequest(
        name: json['name'] as String,
        phoneNumber: json['phoneNumber'] as String?,
        phoneNumber2: json['phoneNumber2'] as String?,
        gender: Gender.fromWire(json['gender'] as String),
        groupId: json['groupId'] as int,
        subGroupId: json['subGroupId'] as int?,
        governorateId: json['governorateId'] as int,
        cityId: json['cityId'] as int?,
        neighborhoodId: json['neighborhoodId'] as int?,
        notes: json['notes'] as String?,
      );

  UpdatePersonRequest _updateRequestFrom(Map<String, dynamic> json) => UpdatePersonRequest(
        id: json['id'] as int,
        name: json['name'] as String,
        phoneNumber: json['phoneNumber'] as String?,
        phoneNumber2: json['phoneNumber2'] as String?,
        gender: Gender.fromWire(json['gender'] as String),
        groupId: json['groupId'] as int,
        subGroupId: json['subGroupId'] as int?,
        governorateId: json['governorateId'] as int,
        cityId: json['cityId'] as int?,
        neighborhoodId: json['neighborhoodId'] as int?,
        notes: json['notes'] as String?,
      );
}
