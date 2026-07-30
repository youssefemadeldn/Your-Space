import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';

abstract class GroupRepository {
  Future<Either<Failure, PaginatedResult<Group>>> getGroups({
    String? search,
    required int pageIndex,
    required int pageSize,
  });

  Future<Either<Failure, Group>> createGroup({required String name, String? nameAr});

  Future<Either<Failure, Group>> updateGroup({
    required int id,
    required String name,
    String? nameAr,
  });
}
