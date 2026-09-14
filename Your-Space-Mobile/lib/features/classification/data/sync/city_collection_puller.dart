import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/collection_puller.dart';
import '../../domain/repositories/base_city_repository.dart';

/// `SyncService`'s collection: 'cities' strategy — a thin wrapper over
/// `CityRepository.refreshCities()`, which already does the fetch +
/// diff/tombstone work (Tier 3 interim mode, design doc §6, row 8.10).
/// Mirrors `GovernorateCollectionPuller`.
///
/// See `PersonOutboxReplayer`'s doc comment for why the `@Named` tag exists:
/// it reserves this registration's identity so it can coexist with the
/// other entities' pullers under injectable's duplicate-registration check.
/// `RegisterModule.collectionPullers` collects all of them back into the
/// `List<CollectionPuller>` `SyncService` actually wants.
@Named('city')
@LazySingleton(as: CollectionPuller)
class CityCollectionPuller implements CollectionPuller {
  final CityRepository _cityRepository;

  CityCollectionPuller(this._cityRepository);

  @override
  String get collection => 'cities';

  @override
  Future<Either<Failure, Unit>> pull() => _cityRepository.refreshCities();
}
