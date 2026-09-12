import 'package:drift/drift.dart';

/// Pending offline writes, replayed by `SyncService` (Tier 2, see
/// `doc/local-first-sync-design.md` §5).
class OutboxTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()(); // 'person', 'group', 'eventGuest', ...
  IntColumn get entityId => integer()(); // local temp id or real server id
  TextColumn get operation => text()(); // 'create' | 'update' | 'delete'
  TextColumn get payloadJson =>
      text()(); // request body, shaped like *_request.dart's toJson()
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  /// When this row was last attempted (null = never attempted yet). Drives
  /// `SyncService`'s exponential backoff schedule — `retryCount` alone can't
  /// tell "due now" from "due in 4 more minutes" (design doc §5).
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
}
