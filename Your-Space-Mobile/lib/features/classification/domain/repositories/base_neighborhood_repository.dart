import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/entities/neighborhood.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';

abstract class NeighborhoodRepository {
  Future<Either<Failure, PaginatedResult<Neighborhood>>> getNeighborhoods({
    required int cityId,
    String? search,
    required int pageIndex,
    required int pageSize,
  });

  Future<Either<Failure, Neighborhood>> createNeighborhood({
    required int cityId,
    required String name,
    String? nameAr,
  });

  Future<Either<Failure, Neighborhood>> updateNeighborhood({
    required int cityId,
    required int id,
    required String name,
    String? nameAr,
  });

  Future<Either<Failure, Unit>> deleteNeighborhood({required int cityId, required int id});
}
