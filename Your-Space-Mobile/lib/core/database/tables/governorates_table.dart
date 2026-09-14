import 'package:drift/drift.dart';

/// Local mirror of the synced [Governorate] entity (`lib/core/entities/governorate.dart`).
///
/// Top-level entity — no parent FK column (Governorate has no parent in the
/// location hierarchy). `id` is the server id; a negative value marks a
/// not-yet-synced record created offline (Tier 2 temp-id, see
/// `doc/local-first-sync-design.md` §5).
///
/// [isLocked] is cached even though no mobile UI edits Governorates today —
/// it's a single boolean the server already computes on every fetch, and
/// carrying it now avoids a future schema migration the moment an
/// edit-affordance feature needs to disable editing on the 27 global rows.
///
/// `updatedAt`, `isDeleted`, and `isDirty` are sync-only columns with no
/// entity equivalent — they exist from Tier 1 onward so no schema migration
/// is needed when Tier 2/3 land (design doc §4), mirroring `GroupsTable`.
class GovernoratesTable extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get nameAr => text().nullable()();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  // Tier 3 watermark field — nullable until the backend exposes `UpdatedAt`
  // (design doc §6/§11 row 8.5); Tier 1 upserts have no value to put here yet.
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // tombstone, Tier 3
  BoolColumn get isDirty =>
      boolean().withDefault(const Constant(false))(); // pending outbox row, Tier 2

  @override
  Set<Column> get primaryKey => {id};
}
