import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/city.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import '../../domain/repositories/base_city_repository.dart';
import '../datasources/city_remote_data_source_impl.dart';
import '../models/create_city_request.dart';
import '../models/update_city_request.dart';

@LazySingleton(as: CityRepository)
class CityRepositoryImpl implements CityRepository {
  final CityRemoteDataSourceImpl _remote;

  CityRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, PaginatedResult<City>>> getCities({
    required int governorateId,
    String? search,
    required int pageIndex,
    required int pageSize,
  }) async {
    final result = await _remote.getCities(
      governorateId: governorateId,
      search: search,
      pageIndex: pageIndex,
      pageSize: pageSize,
    );
    return result.fold(Left.new, (response) => Right(response.toResult((r) => r.toEntity())));
  }

  @override
  Future<Either<Failure, City>> createCity({
    required int governorateId,
    required String name,
    String? nameAr,
  }) async {
    final result = await _remote.createCity(governorateId, CreateCityRequest(name: name, nameAr: nameAr));
    return result.fold(Left.new, (response) => Right(response.toEntity()));
  }

  @override
  Future<Either<Failure, City>> updateCity({
    required int governorateId,
    required int id,
    required String name,
    String? nameAr,
  }) async {
    final result =
        await _remote.updateCity(governorateId, id, UpdateCityRequest(name: name, nameAr: nameAr));
    return result.fold(Left.new, (response) => Right(response.toEntity()));
  }

  @override
  Future<Either<Failure, Unit>> deleteCity({required int governorateId, required int id}) =>
      _remote.deleteCity(governorateId, id);
}
