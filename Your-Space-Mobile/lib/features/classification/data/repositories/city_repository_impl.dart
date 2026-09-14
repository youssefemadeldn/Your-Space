import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/city.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import '../../domain/repositories/base_city_repository.dart';
import '../datasources/base_city_data_source.dart';
import '../datasources/city_local_data_source_impl.dart';
import '../models/create_city_request.dart';
import '../models/update_city_request.dart';

@LazySingleton(as: CityRepository)
class CityRepositoryImpl implements CityRepository {
  final BaseCityDataSource _remote;
  final CityLocalDataSourceImpl _local;

  CityRepositoryImpl(
    @Named('remote') this._remote,
    @Named('local') this._local,
  );

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
  Stream<List<City>> watchCities({required int governorateId, String? search, required int limit}) =>
      _local.watchCities(governorateId: governorateId, search: search, limit: limit);

  @override
  Future<int> countCities({required int governorateId, String? search}) =>
      _local.countCities(governorateId: governorateId, search: search);

  @override
  Future<Either<Failure, City>> createCity({
    required int governorateId,
    required String name,
    String? nameAr,
  }) async {
    final result = await _remote.createCity(governorateId, CreateCityRequest(name: name, nameAr: nameAr));
    if (result.isLeft()) return result.fold(Left.new, (_) => throw StateError('unreachable'));
    final city = result.getOrElse(() => throw StateError('unreachable')).toEntity();
    // Transitional Tier 1 write path (design doc §3) — superseded by the
    // outbox once row 8.9 lands. Upserting on success keeps the local cache
    // from going stale until the next Tier 3 pull.
    await _local.saveCity(city);
    return Right(city);
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
    if (result.isLeft()) return result.fold(Left.new, (_) => throw StateError('unreachable'));
    final city = result.getOrElse(() => throw StateError('unreachable')).toEntity();
    await _local.saveCity(city);
    return Right(city);
  }

  @override
  Future<Either<Failure, Unit>> deleteCity({required int governorateId, required int id}) async {
    final result = await _remote.deleteCity(governorateId, id);
    if (result.isLeft()) return result;
    await _local.deleteCityLocal(id);
    return result;
  }
}
