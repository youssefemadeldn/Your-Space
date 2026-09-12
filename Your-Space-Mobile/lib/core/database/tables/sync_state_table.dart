import 'package:drift/drift.dart';

/// One row per synced collection, holding the delta-sync watermark
/// (Tier 3, see `doc/local-first-sync-design.md` §6). Unused until then —
/// created now so the schema doesn't need a breaking migration per tier.
class SyncStateTable extends Table {
  TextColumn get collection => text()(); // 'persons', 'groups', ...
  TextColumn get cursor =>
      text().nullable()(); // opaque server watermark, null = never synced
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {collection};
}
