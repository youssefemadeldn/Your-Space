import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/network/failure.dart';

/// Per-entity-type replay strategy `SyncService` dispatches an outbox row
/// to. Lives in core (so `SyncService` can depend on it) but is implemented
/// per feature (so core never imports a feature's remote/local data
/// sources — the layer rule cuts both ways) — every
/// `@LazySingleton(as: OutboxReplayer)` implementation is collected into
/// `List<OutboxReplayer>` and injected into `SyncService` via injectable's
/// multi-binding.
abstract class OutboxReplayer {
  /// Matches `OutboxTable.entityType` ('person', 'group', ...).
  String get entityType;

  /// Attempts one row: performs the HTTP call via the feature's own
  /// `*_remote_data_source_impl` and, on success, whatever local
  /// reconciliation/confirmation that entity type needs. Returns
  /// `Right(payload)` where `payload` is an opaque success value only the
  /// calling feature interprets (e.g. the real `Person` for a create) —
  /// `SyncService` stays entity-agnostic and never inspects it.
  ///
  /// **Contract:** on a `Right` result, the implementation must itself
  /// resolve the row (typically by deleting it, as
  /// `PersonLocalDataSourceImpl.reconcileCreatedPerson`/`confirmSyncedPerson`
  /// do) — `SyncService` never deletes an outbox row on success. A replayer
  /// that returns `Right` without resolving the row leaves it perpetually
  /// "due"; `SyncService.replayAll()` guards against looping forever on
  /// such a bug, but the row would then be silently stuck rather than
  /// retried with backoff like a real failure.
  Future<Either<Failure, Object?>> replay(OutboxTableData row);
}
