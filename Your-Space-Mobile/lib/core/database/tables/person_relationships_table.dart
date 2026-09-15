import 'package:drift/drift.dart';

/// Local mirror of the synced [PersonRelationship] entity
/// (`lib/core/entities/person_relationship.dart`).
///
/// `id` is the server id; a negative value marks a not-yet-synced record
/// created offline (Tier 2 temp-id, see `doc/local-first-sync-design.md` §5).
/// PersonRelationship is permanently hard-delete-only (no soft-delete
/// column ever planned — row 9 cross-cutting decision), so Tier 3 for this
/// table runs design doc §6's "full-refetch-as-delta" mode forever — no
/// `updatedAt` watermark column, matching `EventGuestsTable`.
///
/// `inverseId` is the local mirror of the backend's `InverseRelationshipId`
/// (row 9.13's "symmetric pair" mechanism) — before sync, it holds the
/// *other* temp id of the optimistically-created pair; after sync, the real
/// inverse row's real id. Nullable because a row synced before this concept
/// existed (impossible today, but matches every other nullable-until-synced
/// field's convention) would have none.
class PersonRelationshipsTable extends Table {
  IntColumn get id => integer()();
  IntColumn get personId => integer()();
  IntColumn get relatedPersonId => integer()();
  TextColumn get relatedPersonName => text()();
  TextColumn get relationType => text()(); // RelationType wire value, e.g. "Father"
  IntColumn get inverseId => integer().nullable()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // tombstone, Tier 3
  BoolColumn get isDirty =>
      boolean().withDefault(const Constant(false))(); // pending outbox row, Tier 2

  @override
  Set<Column> get primaryKey => {id};
}
