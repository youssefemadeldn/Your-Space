import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/entities/governorate.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';

/// No update/delete — Governorate has no dedicated management screen, per
/// the locked spec's confirmed asymmetry (users can create custom
/// governorates via the wizard's inline "+ Add new" but never rename/delete
/// them from mobile this sprint).
abstract class GovernorateRepository {
  Future<Either<Failure, PaginatedResult<Governorate>>> getGovernorates({
    String? search,
    required int pageIndex,
    required int pageSize,
  });

  Future<Either<Failure, Governorate>> createGovernorate({required String name, String? nameAr});
}
