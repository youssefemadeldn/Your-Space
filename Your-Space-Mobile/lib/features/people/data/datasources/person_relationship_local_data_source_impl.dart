import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/person_relationship.dart';
import 'package:your_space_mobile/core/entities/relation_type.dart';

/// Drift-backed local store for PersonRelationships — the Tier 1 read path
/// (CLAUDE.md Architecture rule 7), mirrors `EventGuestLocalDataSourceImpl`.
/// Does not implement `BasePersonRelationshipDataSource`: it's typed
/// concretely in `PersonRelationshipRepositoryImpl` so its
/// `save*`/`queue*`/`reconcile*` write methods (no direct remote
/// equivalent) are reachable.
@Named('local')
@lazySingleton
class PersonRelationshipLocalDataSourceImpl {
  final AppDatabase _db;

  PersonRelationshipLocalDataSourceImpl(this._db);

  /// Reactive read path, scoped to one person — the local table holds *all*
  /// the user's relationships across every person; filtering by `personId`
  /// is a plain `WHERE` clause (design doc §3).
  Stream<List<PersonRelationship>> watchRelationships({required int personId, required int limit}) {
    final query = _db.select(_db.personRelationshipsTable)
      ..where((t) => t.isDeleted.equals(false) & t.personId.equals(personId))
      ..limit(limit);
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  /// Parent-agnostic reactive read — feeds the Tier 3 full-refetch diff. No
  /// known screen caller yet (kept as a documented primitive, mirrors
  /// `CityLocalDataSourceImpl.watchAllCities`'s own "no known caller today"
  /// precedent).
  Stream<List<PersonRelationship>> watchAllRelationships({required int limit}) {
    final query = _db.select(_db.personRelationshipsTable)
      ..where((t) => t.isDeleted.equals(false))
      ..limit(limit);
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  /// Tier 1 upsert, no tombstoning — kept as a documented primitive.
  /// `refreshRelationships()` (Tier 3, row 9.14) uses
  /// `applyPersonRelationshipsSnapshot` instead.
  Future<void> saveRelationships(List<PersonRelationship> relationships) => _db.batch(
        (batch) => batch.insertAllOnConflictUpdate(
          _db.personRelationshipsTable,
          relationships.map(_toCompanion).toList(),
        ),
      );

  /// One-shot lookup of a single local row by id — lets
  /// `PersonRelationshipOutboxReplayer` read the temp pair's `inverseId`
  /// (set at queue time) before it has the server's real ids to reconcile
  /// with. No remote equivalent.
  Future<PersonRelationship?> getLocalRelationship(int id) async {
    final row = await (_db.select(_db.personRelationshipsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  /// Tier 2 optimistic write (design doc §5, row 9.13's "symmetric pair"
  /// mechanism) — inserts **both** [forward] and [inverse] under fresh
  /// negative temp ids (linked to each other via `inverseId`, mirroring the
  /// backend's own `InverseRelationshipId` pairing) and appends **one**
  /// outbox row for the pair, all in one transaction. The single outbox
  /// payload carries everything the backend needs to derive the inverse
  /// itself (`personId`, `relatedPersonId`, `relationType`) — no bulk-shaped
  /// vocabulary needed, matching the "one outbox row per user action" model.
  Future<int> queuePersonRelationshipPair({
    required PersonRelationship forward,
    required PersonRelationship inverse,
    required String payloadJson,
  }) =>
      _db.transaction(() async {
        await _db.into(_db.personRelationshipsTable).insertOnConflictUpdate(
              _toCompanion(forward, isDirty: true),
            );
        await _db.into(_db.personRelationshipsTable).insertOnConflictUpdate(
              _toCompanion(inverse, isDirty: true),
            );
        return _db.into(_db.outboxTable).insert(
              OutboxTableCompanion.insert(
                entityType: 'personRelationship',
                entityId: forward.id,
                operation: 'create',
                payloadJson: payloadJson,
              ),
            );
      });

  /// Called after a queued pair-create syncs successfully: resolves **both**
  /// temp rows to their real ids in one transaction — the paired
  /// counterpart to every other entity's single-row
  /// `reconcileCreated<Entity>`. [tempForwardId]/[tempInverseId] are the two
  /// negative ids [queuePersonRelationshipPair] created; [realForward]/
  /// [realInverse] are the server-confirmed rows (already cross-linked via
  /// `inverseId`).
  Future<void> confirmSyncedPersonRelationshipPair({
    required int tempForwardId,
    required int tempInverseId,
    required PersonRelationship realForward,
    required PersonRelationship realInverse,
    required int replayedOutboxRowId,
  }) =>
      _db.transaction(() async {
        await _db.into(_db.personRelationshipsTable).insertOnConflictUpdate(_toCompanion(realForward));
        await _db.into(_db.personRelationshipsTable).insertOnConflictUpdate(_toCompanion(realInverse));
        await (_db.delete(_db.personRelationshipsTable)..where((t) => t.id.equals(tempForwardId))).go();
        await (_db.delete(_db.personRelationshipsTable)..where((t) => t.id.equals(tempInverseId))).go();
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();
      });

  /// Tier 2 optimistic delete (design doc §5) — removing the forward row
  /// also removes its paired inverse row locally (the backend cascades the
  /// same way, per `PersonRelationshipService.DeleteAsync`'s own doc
  /// comment). Mirrors `EventGuestLocalDataSourceImpl.queueDeletedEventGuest`'s
  /// two-path shape: a never-synced temp pair is removed locally with no
  /// network call; a real-id pair is optimistically tombstoned and queued.
  Future<void> queueDeletedPersonRelationship(int id, {required String payloadJson}) => _db.transaction(() async {
        final row = await (_db.select(_db.personRelationshipsTable)..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        final inverseId = row?.inverseId;

        if (id < 0) {
          await (_db.delete(_db.personRelationshipsTable)..where((t) => t.id.equals(id))).go();
          await (_db.delete(_db.outboxTable)
                ..where((t) => t.entityType.equals('personRelationship') & t.entityId.equals(id)))
              .go();
          if (inverseId != null) {
            await (_db.delete(_db.personRelationshipsTable)..where((t) => t.id.equals(inverseId))).go();
          }
          return;
        }

        await (_db.update(_db.personRelationshipsTable)..where((t) => t.id.equals(id)))
            .write(const PersonRelationshipsTableCompanion(isDeleted: Value(true), isDirty: Value(true)));
        if (inverseId != null) {
          await (_db.update(_db.personRelationshipsTable)..where((t) => t.id.equals(inverseId)))
              .write(const PersonRelationshipsTableCompanion(isDeleted: Value(true)));
        }
        await _db.into(_db.outboxTable).insert(
              OutboxTableCompanion.insert(
                entityType: 'personRelationship',
                entityId: id,
                operation: 'delete',
                payloadJson: payloadJson,
              ),
            );
      });

  /// Called after a queued delete syncs successfully: hard-removes both the
  /// tombstoned row and its paired inverse (if still present locally), plus
  /// the outbox row, in one transaction.
  Future<void> confirmDeletedPersonRelationship(int id, {required int replayedOutboxRowId}) =>
      _db.transaction(() async {
        final row = await (_db.select(_db.personRelationshipsTable)..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        await (_db.delete(_db.personRelationshipsTable)..where((t) => t.id.equals(id))).go();
        if (row?.inverseId case final int inverseId) {
          await (_db.delete(_db.personRelationshipsTable)..where((t) => t.id.equals(inverseId))).go();
        }
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();
      });

  /// Tier 3 "full refetch as delta" (design doc §6) — **permanent**, not an
  /// interim stage (row 9 cross-cutting decision: PersonRelationship is
  /// hard-delete-only). Mirrors `EventGuestLocalDataSourceImpl.
  /// applyEventGuestsSnapshot`.
  Future<void> applyPersonRelationshipsSnapshot(List<PersonRelationship> serverRelationships) =>
      _db.transaction(() async {
        final dirtyIds = (await (_db.select(_db.personRelationshipsTable)..where((t) => t.isDirty.equals(true)))
                .get())
            .map((r) => r.id)
            .toSet();
        final toUpsert = serverRelationships.where((r) => !dirtyIds.contains(r.id)).toList();
        await _db.batch(
          (batch) => batch.insertAllOnConflictUpdate(
            _db.personRelationshipsTable,
            toUpsert.map(_toCompanion).toList(),
          ),
        );

        final serverIds = serverRelationships.map((r) => r.id).toSet();
        await (_db.update(_db.personRelationshipsTable)
              ..where(
                (t) => t.id.isBiggerThanValue(0) & t.isDirty.equals(false) & t.id.isNotIn(serverIds),
              ))
            .write(const PersonRelationshipsTableCompanion(isDeleted: Value(true)));
      });

  PersonRelationship _toEntity(PersonRelationshipsTableData row) => PersonRelationship(
        id: row.id,
        personId: row.personId,
        relatedPersonId: row.relatedPersonId,
        relatedPersonName: row.relatedPersonName,
        relationType: RelationType.fromWire(row.relationType),
        inverseId: row.inverseId,
      );

  PersonRelationshipsTableCompanion _toCompanion(PersonRelationship relationship, {bool isDirty = false}) =>
      PersonRelationshipsTableCompanion.insert(
        id: Value(relationship.id),
        personId: relationship.personId,
        relatedPersonId: relationship.relatedPersonId,
        relatedPersonName: relationship.relatedPersonName,
        relationType: relationship.relationType.toWire(),
        inverseId: Value(relationship.inverseId),
        isDeleted: const Value(false),
        isDirty: Value(isDirty),
      );
}
