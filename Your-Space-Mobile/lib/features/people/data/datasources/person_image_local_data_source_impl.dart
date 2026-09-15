import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/person_image_ref.dart';

/// Drift-backed local store for PersonImages — the Tier 1 read path
/// (CLAUDE.md Architecture rule 7), mirrors `EventGuestLocalDataSourceImpl`.
/// Bookkeeping-only (object keys, never a presigned URL — see the table's
/// own doc comment): `getImages`'s actual, renderable-URL network path
/// (`PersonImageRepositoryImpl.getImages`) is untouched by this row.
@Named('local')
@lazySingleton
class PersonImageLocalDataSourceImpl {
  final AppDatabase _db;

  PersonImageLocalDataSourceImpl(this._db);

  /// Reactive read path, scoped to one person. No known screen caller yet
  /// (kept as a documented primitive, mirrors
  /// `PersonRelationshipLocalDataSourceImpl.watchRelationships`'s own "no
  /// caller today" precedent).
  Stream<List<PersonImageRef>> watchImages({required int personId, required int limit}) {
    final query = _db.select(_db.personImagesTable)
      ..where((t) => t.isDeleted.equals(false) & t.personId.equals(personId))
      ..limit(limit);
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  /// Parent-agnostic reactive read — feeds the Tier 3 full-refetch diff.
  Stream<List<PersonImageRef>> watchAllImages({required int limit}) {
    final query = _db.select(_db.personImagesTable)
      ..where((t) => t.isDeleted.equals(false))
      ..limit(limit);
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  /// Tier 1 upsert, no tombstoning — kept as a documented primitive.
  /// `refreshImages()` (Tier 3, row 9.18) uses `applyPersonImagesSnapshot`
  /// instead.
  Future<void> saveImages(List<PersonImageRef> images) => _db.batch(
        (batch) => batch.insertAllOnConflictUpdate(_db.personImagesTable, images.map(_toCompanion).toList()),
      );

  /// Called after a queued upload syncs successfully: inserts the
  /// server-confirmed row and removes the outbox row, in one transaction.
  /// Unlike every other entity's `reconcileCreated<Entity>`, there is no
  /// temp-id row to delete first — `queuePersonImageUpload` never inserts
  /// an optimistic local row (there is nothing to insert until the file has
  /// actually uploaded; the wizard's own in-memory staged-photo state
  /// already covers the "pending" UI).
  Future<void> confirmUploadedImage(PersonImageRef image, {required int replayedOutboxRowId}) =>
      _db.transaction(() async {
        await _db.into(_db.personImagesTable).insertOnConflictUpdate(_toCompanion(image));
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();
      });

  /// Tier 2 optimistic write (design doc §5, row 9.17): appends one outbox
  /// row carrying everything the replayer needs (`personId`,
  /// `localFilePath`, `isPrimary`) — per design doc §9's own worked example.
  /// [tempId] exists purely as the outbox row's `entityId`; no
  /// `PersonImagesTable` row is inserted for it (see this class's own doc
  /// comment and `confirmUploadedImage`'s).
  Future<int> queuePersonImageUpload({required int tempId, required String payloadJson}) =>
      _db.into(_db.outboxTable).insert(
            OutboxTableCompanion.insert(
              entityType: 'personImage',
              entityId: tempId,
              operation: 'create',
              payloadJson: payloadJson,
            ),
          );

  /// No remote equivalent — hard-removes an outbox row with no confirmation
  /// step. Used only when `PersonImageOutboxReplayer` gives up on a
  /// 'create' row because its staged file is missing (design doc §9's own
  /// stated policy: drop, don't retry forever).
  Future<void> discardOutboxRow(int outboxRowId) =>
      (_db.delete(_db.outboxTable)..where((t) => t.id.equals(outboxRowId))).go();

  /// Tier 2 optimistic delete — always targets an already-synced (real,
  /// positive) id: a staged-but-not-yet-uploaded photo is discarded purely
  /// client-side by the wizard (never reaches this method), so there is no
  /// temp-id fast path to mirror here, unlike every other entity's
  /// `queueDeleted<Entity>`.
  Future<void> queueDeletedImage(int id, {required String payloadJson}) => _db.transaction(() async {
        await (_db.update(_db.personImagesTable)..where((t) => t.id.equals(id)))
            .write(const PersonImagesTableCompanion(isDeleted: Value(true), isDirty: Value(true)));
        await _db.into(_db.outboxTable).insert(
              OutboxTableCompanion.insert(
                entityType: 'personImage',
                entityId: id,
                operation: 'delete',
                payloadJson: payloadJson,
              ),
            );
      });

  /// Called after a queued delete syncs successfully: hard-removes the
  /// tombstoned row and the outbox row, in one transaction.
  Future<void> confirmDeletedImage(int id, {required int replayedOutboxRowId}) => _db.transaction(() async {
        await (_db.delete(_db.personImagesTable)..where((t) => t.id.equals(id))).go();
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();
      });

  /// Tier 2 optimistic "set primary" — an `'update'` outbox row. Always
  /// targets an already-synced (real) id, same as delete. Clears
  /// `isPrimary` on every sibling row locally so the cache stays consistent
  /// with the "exactly one primary" server invariant, even before sync.
  Future<int> queueSetPrimary({required int personId, required int id, required String payloadJson}) =>
      _db.transaction(() async {
        await (_db.update(_db.personImagesTable)..where((t) => t.personId.equals(personId)))
            .write(const PersonImagesTableCompanion(isPrimary: Value(false)));
        await (_db.update(_db.personImagesTable)..where((t) => t.id.equals(id)))
            .write(const PersonImagesTableCompanion(isPrimary: Value(true), isDirty: Value(true)));
        return _db.into(_db.outboxTable).insert(
              OutboxTableCompanion.insert(
                entityType: 'personImage',
                entityId: id,
                operation: 'update',
                payloadJson: payloadJson,
              ),
            );
      });

  /// Called after a queued "set primary" syncs successfully: clears
  /// `isDirty` on the confirmed row and removes the outbox row.
  Future<void> confirmSyncedPrimary(int id, {required int replayedOutboxRowId}) => _db.transaction(() async {
        await (_db.update(_db.personImagesTable)..where((t) => t.id.equals(id)))
            .write(const PersonImagesTableCompanion(isDirty: Value(false)));
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();
      });

  /// Tier 3 "full refetch as delta" (design doc §6) — **permanent**, not an
  /// interim stage (row 9 cross-cutting decision: PersonImage is
  /// hard-delete-only). Mirrors `EventGuestLocalDataSourceImpl.
  /// applyEventGuestsSnapshot`.
  Future<void> applyPersonImagesSnapshot(List<PersonImageRef> serverImages) => _db.transaction(() async {
        final dirtyIds = (await (_db.select(_db.personImagesTable)..where((t) => t.isDirty.equals(true))).get())
            .map((r) => r.id)
            .toSet();
        final toUpsert = serverImages.where((i) => !dirtyIds.contains(i.id)).toList();
        await _db.batch(
          (batch) => batch.insertAllOnConflictUpdate(_db.personImagesTable, toUpsert.map(_toCompanion).toList()),
        );

        final serverIds = serverImages.map((i) => i.id).toSet();
        await (_db.update(_db.personImagesTable)
              ..where(
                (t) => t.id.isBiggerThanValue(0) & t.isDirty.equals(false) & t.id.isNotIn(serverIds),
              ))
            .write(const PersonImagesTableCompanion(isDeleted: Value(true)));
      });

  PersonImageRef _toEntity(PersonImagesTableData row) =>
      PersonImageRef(id: row.id, personId: row.personId, objectKey: row.objectKey, isPrimary: row.isPrimary);

  PersonImagesTableCompanion _toCompanion(PersonImageRef image) => PersonImagesTableCompanion.insert(
        id: Value(image.id),
        personId: image.personId,
        objectKey: image.objectKey,
        isPrimary: Value(image.isPrimary),
        isDeleted: const Value(false),
        isDirty: const Value(false),
      );
}
