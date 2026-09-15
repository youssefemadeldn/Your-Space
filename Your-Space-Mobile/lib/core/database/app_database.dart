import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:injectable/injectable.dart';

import 'tables/cities_table.dart';
import 'tables/event_guests_table.dart';
import 'tables/events_table.dart';
import 'tables/governorates_table.dart';
import 'tables/groups_table.dart';
import 'tables/neighborhoods_table.dart';
import 'tables/outbox_table.dart';
import 'tables/person_images_table.dart';
import 'tables/person_relationships_table.dart';
import 'tables/persons_table.dart';
import 'tables/subgroups_table.dart';
import 'tables/sync_state_table.dart';

part 'app_database.g.dart';

/// The single on-device store synced features read from and write to
/// (`doc/local-first-sync-design.md`, CLAUDE.md Architecture rule 7).
///
/// One instance for the app lifetime. The connection opens lazily under the
/// hood — this constructor is synchronous, so a plain `@lazySingleton` is
/// enough; no `@preResolve` async DI wiring is needed.
@lazySingleton
@DriftDatabase(
  tables: [
    PersonsTable,
    GroupsTable,
    GovernoratesTable,
    CitiesTable,
    SubGroupsTable,
    NeighborhoodsTable,
    EventsTable,
    EventGuestsTable,
    PersonRelationshipsTable,
    PersonImagesTable,
    OutboxTable,
    SyncStateTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test-only seam: build the database over an arbitrary executor (e.g. an
  /// in-memory `NativeDatabase`) instead of the real on-disk file.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 11;

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
          // v2 -> v3: GroupsTable, Groups' row 7.1 (local-first rollout for
          // Groups, same reasoning as above — no shipped users yet).
          if (from < 3) {
            await m.createTable(groupsTable);
          }
          // v3 -> v4: GovernoratesTable, Classification's row 8.1 (local-first
          // rollout for Governorate — same reasoning as above, no shipped
          // users yet).
          if (from < 4) {
            await m.createTable(governoratesTable);
          }
          // v4 -> v5: CitiesTable, Classification's row 8.7 (local-first
          // rollout for City — same reasoning as above, no shipped users yet).
          if (from < 5) {
            await m.createTable(citiesTable);
          }
          // v5 -> v6: SubGroupsTable, Classification's row 8.13 (local-first
          // rollout for SubGroup — same reasoning as above, no shipped users
          // yet).
          if (from < 6) {
            await m.createTable(subGroupsTable);
          }
          // v6 -> v7: NeighborhoodsTable, Classification's row 8.19
          // (local-first rollout for Neighborhood — same reasoning as above,
          // no shipped users yet).
          if (from < 7) {
            await m.createTable(neighborhoodsTable);
          }
          // v7 -> v8: EventsTable, Row 9.1 (local-first rollout for Event —
          // same reasoning as above, no shipped users yet).
          if (from < 8) {
            await m.createTable(eventsTable);
          }
          // v8 -> v9: EventGuestsTable, Row 9.7 (local-first rollout for
          // EventGuest — same reasoning as above, no shipped users yet).
          if (from < 9) {
            await m.createTable(eventGuestsTable);
          }
          // v9 -> v10: PersonRelationshipsTable, Row 9.11 (local-first
          // rollout for PersonRelationship — same reasoning as above, no
          // shipped users yet).
          if (from < 10) {
            await m.createTable(personRelationshipsTable);
          }
          // v10 -> v11: PersonImagesTable, Row 9.15 (local-first rollout for
          // PersonImage — same reasoning as above, no shipped users yet).
          // Final schema version for Row 9.
          if (from < 11) {
            await m.createTable(personImagesTable);
          }
        },
      );
}

QueryExecutor _openConnection() => driftDatabase(name: 'app_database');
