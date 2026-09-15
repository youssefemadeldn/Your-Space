import 'package:drift/drift.dart';

/// Local mirror of the synced [Neighborhood] entity
/// (`lib/core/entities/neighborhood.dart`).
///
/// `cityId` is a plain FK column — no drift-level foreign-key constraint
/// (matches `PersonsTable`'s denormalized parent-id columns); `watchNeighborhoods`
/// filters on it in a drift `WHERE` clause (design doc §3). `id` is the
/// server id; a negative value marks a not-yet-synced record created offline
/// (Tier 2 temp-id, see `doc/local-first-sync-design.md` §5).
///
/// `updatedAt`, `isDeleted`, and `isDirty` are sync-only columns with no
/// entity equivalent — they exist from Tier 1 onward so no schema migration
/// is needed when Tier 2/3 land (design doc §4), mirroring `CitiesTable`.
class NeighborhoodsTable extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get nameAr => text().nullable()();
  IntColumn get cityId => integer()();
  // Tier 3 watermark field — nullable until the backend exposes `UpdatedAt`
  // (design doc §6/§11 row 8.23); Tier 1 upserts have no value to put here yet.
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // tombstone, Tier 3
  BoolColumn get isDirty =>
      boolean().withDefault(const Constant(false))(); // pending outbox row, Tier 2

  @override
  Set<Column> get primaryKey => {id};
}
