import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/collection_puller.dart';
import '../../domain/repositories/base_neighborhood_repository.dart';

@Named('neighborhood')
@LazySingleton(as: CollectionPuller)
class NeighborhoodCollectionPuller implements CollectionPuller {
  final NeighborhoodRepository _neighborhoodRepository;

  NeighborhoodCollectionPuller(this._neighborhoodRepository);

  @override
  String get collection => 'neighborhoods';

  @override
  Future<Either<Failure, Unit>> pull() => _neighborhoodRepository.refreshNeighborhoods();
}
