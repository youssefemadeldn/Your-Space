import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/neighborhood.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import '../../domain/repositories/base_neighborhood_repository.dart';
import '../datasources/neighborhood_remote_data_source_impl.dart';
import '../models/create_neighborhood_request.dart';
import '../models/update_neighborhood_request.dart';

@LazySingleton(as: NeighborhoodRepository)
class NeighborhoodRepositoryImpl implements NeighborhoodRepository {
  final NeighborhoodRemoteDataSourceImpl _remote;

  NeighborhoodRepositoryImpl(this._remote);

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
  Future<Either<Failure, Neighborhood>> createNeighborhood({
    required int cityId,
    required String name,
    String? nameAr,
  }) async {
    final result =
        await _remote.createNeighborhood(cityId, CreateNeighborhoodRequest(name: name, nameAr: nameAr));
    return result.fold(Left.new, (response) => Right(response.toEntity()));
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
    return result.fold(Left.new, (response) => Right(response.toEntity()));
  }

  @override
  Future<Either<Failure, Unit>> deleteNeighborhood({required int cityId, required int id}) =>
      _remote.deleteNeighborhood(cityId, id);
}
