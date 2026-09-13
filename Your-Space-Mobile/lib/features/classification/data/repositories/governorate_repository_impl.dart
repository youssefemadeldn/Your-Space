import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/governorate.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import '../../domain/repositories/base_governorate_repository.dart';
import '../datasources/base_governorate_data_source.dart';
import '../datasources/governorate_local_data_source_impl.dart';
import '../models/create_governorate_request.dart';

@LazySingleton(as: GovernorateRepository)
class GovernorateRepositoryImpl implements GovernorateRepository {
  final BaseGovernorateDataSource _remote;
  final GovernorateLocalDataSourceImpl _local;

  GovernorateRepositoryImpl(
    @Named('remote') this._remote,
    @Named('local') this._local,
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

  @override
  Future<Either<Failure, Governorate>> createGovernorate({required String name, String? nameAr}) async {
    final result = await _remote.createGovernorate(CreateGovernorateRequest(name: name, nameAr: nameAr));
    if (result.isLeft()) return result.fold(Left.new, (_) => throw StateError('unreachable'));
    final governorate = result.getOrElse(() => throw StateError('unreachable')).toEntity();
    // Transitional Tier 1 write path (design doc §3) — superseded by the
    // outbox once row 8.3 lands. Upserting on success keeps the local
    // cache from going stale until the next Tier 3 pull.
    await _local.saveGovernorate(governorate);
    return Right(governorate);
  }
}
