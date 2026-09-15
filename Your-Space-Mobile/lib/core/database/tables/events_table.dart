import 'package:drift/drift.dart';

/// Local mirror of the synced [Event] entity (`lib/features/events/domain/entities/event.dart`).
///
/// `id` is the server id; a negative value marks a not-yet-synced record
/// created offline (Tier 2 temp-id, see `doc/local-first-sync-design.md` §5).
/// `updatedAt`, `isDeleted`, and `isDirty` are sync-only columns with no
/// entity equivalent — they exist from Tier 1 onward so no schema migration
/// is needed when Tier 2/3 land (design doc §4), mirroring `GroupsTable`.
class EventsTable extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get nameAr => text().nullable()();
  DateTimeColumn get eventDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get totalGuestCount => integer().withDefault(const Constant(0))();
  // Tier 3 watermark field — nullable until the backend exposes `UpdatedAt`
  // (row 9.5); Tier 1 upserts have no value to put here yet.
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // tombstone, Tier 3
  BoolColumn get isDirty =>
      boolean().withDefault(const Constant(false))(); // pending outbox row, Tier 2

  @override
  Set<Column> get primaryKey => {id};
}
