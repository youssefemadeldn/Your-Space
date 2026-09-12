import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:injectable/injectable.dart';

import 'tables/outbox_table.dart';
import 'tables/persons_table.dart';
import 'tables/sync_state_table.dart';

part 'app_database.g.dart';

/// The single on-device store synced features read from and write to
/// (`doc/local-first-sync-design.md`, CLAUDE.md Architecture rule 7).
///
/// One instance for the app lifetime. The connection opens lazily under the
/// hood — this constructor is synchronous, so a plain `@lazySingleton` is
/// enough; no `@preResolve` async DI wiring is needed.
@lazySingleton
@DriftDatabase(tables: [PersonsTable, OutboxTable, SyncStateTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test-only seam: build the database over an arbitrary executor (e.g. an
  /// in-memory `NativeDatabase`) instead of the real on-disk file.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v1 -> v2: OutboxTable.lastAttemptAt, needed for Tier 2's
          // exponential backoff schedule (design doc §5). Additive/nullable
          // — no data loss, no table rebuild. No shipped users on this
          // unreleased feature yet, so a real from-v1 upgrade test isn't
          // warranted; the schema-version + column-reachability check in
          // app_database_test.dart is enough.
          if (from < 2) {
            await m.addColumn(outboxTable, outboxTable.lastAttemptAt);
          }
        },
      );
}

QueryExecutor _openConnection() => driftDatabase(name: 'app_database');
