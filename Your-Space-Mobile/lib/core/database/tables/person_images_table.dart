import 'package:drift/drift.dart';

/// Local mirror of the synced [PersonImage] entity
/// (`lib/core/entities/person_image.dart`).
///
/// `id` is the server id; a negative value marks a not-yet-synced record
/// (Tier 2 temp-id, see `doc/local-first-sync-design.md` §5) — unlike every
/// other entity, PersonImage's 'create' operation (row 9.17) never inserts
/// an optimistic local row at all (there is nothing to insert until the
/// file has actually uploaded — the wizard's own in-memory staged-photo
/// state already covers the "pending" UI, see
/// `PersonWizardCubit`/`StagedPersonPhoto`), so a negative id is only ever
/// seen in the outbox row's own `entityId`, never in this table.
///
/// `objectKey` is the R2 object key, never a resolved URL — a presigned URL
/// expires within minutes/hours and must never be cached as if stable (see
/// `PersonImageProfileDto`'s own doc comment on the backend). This table is
/// bookkeeping-only: it tracks *what images exist* and *which is primary*,
/// not anything renderable. Actually displaying an image still resolves a
/// live presigned URL via the existing nested `getImages` network call,
/// unchanged by this row.
///
/// PersonImage is permanently hard-delete-only (no soft-delete column ever
/// planned — row 9 cross-cutting decision), so Tier 3 for this table runs
/// design doc §6's "full-refetch-as-delta" mode forever — no `updatedAt`
/// watermark column, matching `EventGuestsTable`/`PersonRelationshipsTable`.
class PersonImagesTable extends Table {
  IntColumn get id => integer()();
  IntColumn get personId => integer()();
  TextColumn get objectKey => text()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // tombstone, Tier 3
  BoolColumn get isDirty =>
      boolean().withDefault(const Constant(false))(); // pending outbox row, Tier 2

  @override
  Set<Column> get primaryKey => {id};
}
