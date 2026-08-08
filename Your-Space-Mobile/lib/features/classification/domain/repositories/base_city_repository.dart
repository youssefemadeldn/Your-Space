import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/entities/city.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';

abstract class CityRepository {
  Future<Either<Failure, PaginatedResult<City>>> getCities({
    required int governorateId,
    String? search,
    required int pageIndex,
    required int pageSize,
  });

  Future<Either<Failure, City>> createCity({required int governorateId, required String name, String? nameAr});

  Future<Either<Failure, City>> updateCity({
    required int governorateId,
    required int id,
    required String name,
    String? nameAr,
  });

  Future<Either<Failure, Unit>> deleteCity({required int governorateId, required int id});
}
