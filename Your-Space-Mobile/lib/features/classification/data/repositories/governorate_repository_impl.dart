import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/governorate.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/sync_service.dart';
import '../../domain/repositories/base_governorate_repository.dart';
import '../datasources/base_governorate_data_source.dart';
import '../datasources/governorate_local_data_source_impl.dart';
import '../models/create_governorate_request.dart';

@LazySingleton(as: GovernorateRepository)
class GovernorateRepositoryImpl implements GovernorateRepository {
  final BaseGovernorateDataSource _remote;
  final GovernorateLocalDataSourceImpl _local;
  final SyncService _syncService;

  GovernorateRepositoryImpl(
    @Named('remote') this._remote,
    @Named('local') this._local,
    this._syncService,
  );

  @override
  Future<Either<Failure, PaginatedResult<Governorate>>> getGovernorates({
    String? search,
    required int pageIndex,
    required int pageSize,
  }) async {
    final result = await _remote.getGovernorates(search: search, pageIndex: pageIndex, pageSize: pageSize);
    return result.fold(Left.new, (response) => Right(response.toResult((r) => r.toEntity())));
  }

  @override
  Stream<List<Governorate>> watchGovernorates({String? search, required int limit}) =>
      _local.watchGovernorates(search: search, limit: limit);

  @override
  Future<int> countGovernorates({String? search}) => _local.countGovernorates(search: search);

  int _newTempGovernorateId() => -DateTime.now().microsecondsSinceEpoch;

  /// Builds the [Governorate] draft + JSON-encoded [CreateGovernorateRequest]
  /// payload and queues both via the outbox. Shared by [createGovernorate]
  /// and [createGovernorateAndSync] — only what happens after queuing
  /// differs. Mirrors `GroupRepositoryImpl._queueCreate`.
  Future<(Governorate, int)> _queueCreate({required String name, String? nameAr}) async {
    final governorate = Governorate(id: _newTempGovernorateId(), name: name, nameAr: nameAr);
    final payloadJson = jsonEncode(CreateGovernorateRequest(name: name, nameAr: nameAr).toJson());
    final rowId = await _local.queueGovernorateMutation(
      governorate: governorate,
      operation: 'create',
      payloadJson: payloadJson,
    );
    return (governorate, rowId);
  }

  @override
  Future<Either<Failure, Governorate>> createGovernorate({required String name, String? nameAr}) async {
    final (governorate, _) = await _queueCreate(name: name, nameAr: nameAr);
    return Right(governorate);
  }

  @override
  Future<Either<Failure, Governorate>> createGovernorateAndSync({required String name, String? nameAr}) async {
    final (governorate, rowId) = await _queueCreate(name: name, nameAr: nameAr);
    final result = await _syncService.replayRow(rowId);
    return result.fold(Left.new, (payload) => Right(payload as Governorate? ?? governorate));
  }
}
