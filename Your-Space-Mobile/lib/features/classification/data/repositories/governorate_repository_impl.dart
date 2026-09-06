import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/governorate.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import '../../domain/repositories/base_governorate_repository.dart';
import '../datasources/governorate_remote_data_source_impl.dart';
import '../models/create_governorate_request.dart';

@LazySingleton(as: GovernorateRepository)
class GovernorateRepositoryImpl implements GovernorateRepository {
  final GovernorateRemoteDataSourceImpl _remote;

  GovernorateRepositoryImpl(this._remote);

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
  Future<Either<Failure, Governorate>> createGovernorate({required String name, String? nameAr}) async {
    final result = await _remote.createGovernorate(CreateGovernorateRequest(name: name, nameAr: nameAr));
    return result.fold(Left.new, (response) => Right(response.toEntity()));
  }
}
