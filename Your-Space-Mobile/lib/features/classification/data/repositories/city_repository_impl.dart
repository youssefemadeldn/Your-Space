import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/city.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/sync_service.dart';
import '../../domain/repositories/base_city_repository.dart';
import '../datasources/base_city_data_source.dart';
import '../datasources/city_local_data_source_impl.dart';
import '../models/create_city_request.dart';
import '../models/update_city_request.dart';

@LazySingleton(as: CityRepository)
class CityRepositoryImpl implements CityRepository {
  final BaseCityDataSource _remote;
  final CityLocalDataSourceImpl _local;
  final SyncService _syncService;

  CityRepositoryImpl(
    @Named('remote') this._remote,
    @Named('local') this._local,
    this._syncService,
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

  int _newTempCityId() => -DateTime.now().microsecondsSinceEpoch;

  /// Builds the [City] draft + JSON-encoded create payload (governorateId
  /// included alongside the request body — `CreateCityRequest.toJson()`
  /// omits it since it's normally routed, but `CityOutboxReplayer` needs it
  /// to call `BaseCityDataSource.createCity(governorateId, ...)`) and queues
  /// both via the outbox. Shared by [createCity] and [createCityAndSync].
  Future<(City, int)> _queueCreate({required int governorateId, required String name, String? nameAr}) async {
    final city = City(id: _newTempCityId(), governorateId: governorateId, name: name, nameAr: nameAr);
    final payloadJson = jsonEncode({
      'governorateId': governorateId,
      ...CreateCityRequest(name: name, nameAr: nameAr).toJson(),
    });
    final rowId = await _local.queueCityMutation(city: city, operation: 'create', payloadJson: payloadJson);
    return (city, rowId);
  }

  @override
  Future<Either<Failure, City>> createCity({
    required int governorateId,
    required String name,
    String? nameAr,
  }) async {
    final (city, _) = await _queueCreate(governorateId: governorateId, name: name, nameAr: nameAr);
    return Right(city);
  }

  @override
  Future<Either<Failure, City>> createCityAndSync({
    required int governorateId,
    required String name,
    String? nameAr,
  }) async {
    final (city, rowId) = await _queueCreate(governorateId: governorateId, name: name, nameAr: nameAr);
    final result = await _syncService.replayRow(rowId);
    return result.fold(Left.new, (payload) => Right(payload as City? ?? city));
  }

  @override
  Future<Either<Failure, City>> updateCity({
    required int governorateId,
    required int id,
    required String name,
    String? nameAr,
  }) async {
    final city = City(id: id, governorateId: governorateId, name: name, nameAr: nameAr);
    final payloadJson = jsonEncode({
      'governorateId': governorateId,
      ...UpdateCityRequest(name: name, nameAr: nameAr).toJson(),
    });
    await _local.queueCityMutation(city: city, operation: 'update', payloadJson: payloadJson);
    return Right(city);
  }

  @override
  Future<Either<Failure, Unit>> deleteCity({required int governorateId, required int id}) async {
    await _local.queueDeletedCity(id, payloadJson: jsonEncode({'governorateId': governorateId}));
    return const Right(unit);
  }
}
