import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/entities/subgroup.dart';
import 'package:your_space_mobile/core/network/failure.dart';

abstract class SubGroupRepository {
  Future<Either<Failure, PaginatedResult<SubGroup>>> getSubGroups({
    required int groupId,
    String? search,
    required int pageIndex,
    required int pageSize,
  });

  Future<Either<Failure, SubGroup>> createSubGroup({required int groupId, required String name, String? nameAr});

  Future<Either<Failure, SubGroup>> updateSubGroup({
    required int groupId,
    required int id,
    required String name,
    String? nameAr,
  });

  Future<Either<Failure, Unit>> deleteSubGroup({required int groupId, required int id});
}
