import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/network/failure.dart';

/// Per-collection pull strategy `SyncService` dispatches to. Lives in core
/// (so `SyncService` can depend on it) but is implemented per feature (so
/// core never imports a feature's repository — the layer rule cuts both
/// ways) — every `@LazySingleton(as: CollectionPuller)` implementation is
/// collected into `List<CollectionPuller>` and injected into `SyncService`
/// via injectable's multi-binding. Mirrors `OutboxReplayer` exactly, for the
/// same reason.
abstract class CollectionPuller {
  /// Matches `SyncStateTable.collection` ('persons', 'groups', ...).
  String get collection;

  /// Runs one full pull for this collection. Implementations do their own
  /// diff/tombstone work locally (e.g. `PersonRepositoryImpl.refreshPersons`)
  /// — `SyncService` only tracks the watermark, it never inspects the data.
  Future<Either<Failure, Unit>> pull();
}
