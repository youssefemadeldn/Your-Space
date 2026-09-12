import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/collection_puller.dart';
import '../../domain/repositories/base_person_repository.dart';

/// `SyncService`'s collection: 'persons' strategy — a thin wrapper over
/// `PersonRepository.refreshPersons()`, which already does the fetch +
/// diff/tombstone work (Tier 3, design doc §6).
@LazySingleton(as: CollectionPuller)
class PersonCollectionPuller implements CollectionPuller {
  final PersonRepository _personRepository;

  PersonCollectionPuller(this._personRepository);

  @override
  String get collection => 'persons';

  @override
  Future<Either<Failure, Unit>> pull() => _personRepository.refreshPersons();
}
