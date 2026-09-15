import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/collection_puller.dart';
import '../../domain/repositories/base_neighborhood_repository.dart';

/// Resolves [NeighborhoodRepository] lazily via [GetIt] at pull time — see
/// `PersonCollectionPuller`'s doc comment for why constructor injection here
/// would recreate a circular dependency with `SyncService`.
@Named('neighborhood')
@LazySingleton(as: CollectionPuller)
class NeighborhoodCollectionPuller implements CollectionPuller {
  @override
  String get collection => 'neighborhoods';

  @override
  Future<Either<Failure, Unit>> pull() =>
      GetIt.instance<NeighborhoodRepository>().refreshNeighborhoods();
}
