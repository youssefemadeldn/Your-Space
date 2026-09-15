import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/neighborhood.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import '../../domain/repositories/base_neighborhood_repository.dart';
import '../datasources/base_neighborhood_data_source.dart';
import '../datasources/neighborhood_local_data_source_impl.dart';
import '../models/create_neighborhood_request.dart';
import '../models/update_neighborhood_request.dart';

@LazySingleton(as: NeighborhoodRepository)
class NeighborhoodRepositoryImpl implements NeighborhoodRepository {
  final BaseNeighborhoodDataSource _remote;
  final NeighborhoodLocalDataSourceImpl _local;

  NeighborhoodRepositoryImpl(
    @Named('remote') this._remote,
    @Named('local') this._local,
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

  @override
  Future<Either<Failure, Neighborhood>> createNeighborhood({
    required int cityId,
    required String name,
    String? nameAr,
  }) async {
    final result =
        await _remote.createNeighborhood(cityId, CreateNeighborhoodRequest(name: name, nameAr: nameAr));
    if (result.isLeft()) {
      return result.fold(Left.new, (_) => throw StateError('unreachable'));
    }
    final neighborhood = result.getOrElse(() => throw StateError('unreachable')).toEntity();
    await _local.saveNeighborhood(neighborhood);
    return Right(neighborhood);
  }

  @override
  Future<Either<Failure, Neighborhood>> updateNeighborhood({
    required int cityId,
    required int id,
    required String name,
    String? nameAr,
  }) async {
    final result =
        await _remote.updateNeighborhood(cityId, id, UpdateNeighborhoodRequest(name: name, nameAr: nameAr));
    if (result.isLeft()) {
      return result.fold(Left.new, (_) => throw StateError('unreachable'));
    }
    final neighborhood = result.getOrElse(() => throw StateError('unreachable')).toEntity();
    await _local.saveNeighborhood(neighborhood);
    return Right(neighborhood);
  }

  @override
  Future<Either<Failure, Unit>> deleteNeighborhood({required int cityId, required int id}) async {
    final result = await _remote.deleteNeighborhood(cityId, id);
    if (result.isLeft()) {
      return result.fold(Left.new, (_) => throw StateError('unreachable'));
    }
    await _local.deleteNeighborhoodLocal(id);
    return const Right(unit);
  }
}
