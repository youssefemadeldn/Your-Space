import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/person.dart';

/// Drift-backed local store for People — the Tier 1 read path (CLAUDE.md
/// Architecture rule 7). Does not implement `BasePersonDataSource`: it's
/// typed concretely in `PersonRepositoryImpl` so its `save*` write methods
/// (no remote equivalent) are reachable.
@Named('local')
@lazySingleton
class PersonLocalDataSourceImpl {
  final AppDatabase _db;

  PersonLocalDataSourceImpl(this._db);

  /// Reactive read path. `limit` grows as `loadMore()` is called on the
  /// caller side; this always queries from row 0 (no offset) rather than
  /// tracking a separate page window.
  Stream<List<Person>> watchPersons({
    int? groupId,
    int? subGroupId,
    int? governorateId,
    int? cityId,
    int? neighborhoodId,
    String? search,
    required int limit,
  }) {
    final query = _db.select(_db.personsTable)
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.name)])
      ..limit(limit);
    _applySelectFilters(
      query,
      groupId: groupId,
      subGroupId: subGroupId,
      governorateId: governorateId,
      cityId: cityId,
      neighborhoodId: neighborhoodId,
      search: search,
    );
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  /// One-shot exact count for the same filter set — backs `hasNextPage`
  /// without a `length == limit` heuristic.
  Future<int> countPersons({
    int? groupId,
    int? subGroupId,
    int? governorateId,
    int? cityId,
    int? neighborhoodId,
    String? search,
  }) {
    final countExp = _db.personsTable.id.count();
    final query = _db.selectOnly(_db.personsTable)..addColumns([countExp]);
    query.where(_db.personsTable.isDeleted.equals(false));
    _applySelectOnlyFilters(
      query,
      groupId: groupId,
      subGroupId: subGroupId,
      governorateId: governorateId,
      cityId: cityId,
      neighborhoodId: neighborhoodId,
      search: search,
    );
    return query.map((row) => row.read(countExp) ?? 0).getSingle();
  }

  /// Tier 1 upsert, no tombstoning — kept as a documented primitive for a
  /// future caller that wants a plain bulk replace. `refreshPersons()`
  /// (Tier 3) uses [applyPersonsSnapshot] instead.
  Future<void> savePersons(List<Person> people) => _db.batch(
        (batch) => batch.insertAllOnConflictUpdate(
          _db.personsTable,
          people.map(_toCompanion).toList(),
        ),
      );

  /// Tier 3 "full refetch as delta" (design doc §6). No longer used by
  /// `PersonRepositoryImpl.refreshPersons()` since row 6 switched Person to
  /// real deltas ([applyPersonChanges]) — kept as a documented full-snapshot
  /// primitive. [serverPersons] is the complete, just-fetched owned
  /// collection. Diffs it against local drift by id in one transaction:
  ///  - a row with `isDirty == true` is left untouched — it has a pending
  ///    outbox entry, so the local edit is presumed newer
  ///  - every other server row is upserted (clean: not dirty, not deleted)
  ///  - every local row with id > 0, isDirty == false, whose id is absent
  ///    from [serverPersons] is soft-tombstoned (`isDeleted = true`) — a
  ///    temp (negative) id is never a tombstone candidate; it was never on
  ///    the server to begin with
  Future<void> applyPersonsSnapshot(List<Person> serverPersons) => _db.transaction(() async {
        final dirtyIds = (await (_db.select(_db.personsTable)..where((t) => t.isDirty.equals(true)))
                .get())
            .map((r) => r.id)
            .toSet();
        final toUpsert = serverPersons.where((p) => !dirtyIds.contains(p.id)).toList();
        await _db.batch(
          (batch) => batch.insertAllOnConflictUpdate(_db.personsTable, toUpsert.map(_toCompanion).toList()),
        );

        final serverIds = serverPersons.map((p) => p.id).toSet();
        await (_db.update(_db.personsTable)
              ..where(
                (t) => t.id.isBiggerThanValue(0) & t.isDirty.equals(false) & t.id.isNotIn(serverIds),
              ))
            .write(const PersonsTableCompanion(isDeleted: Value(true)));
      });

  /// Tier 3 real delta application (design doc §6, row 6): [upserts] and
  /// [tombstoneIds] are exactly what the server says changed on this page —
  /// no absence inference, unlike [applyPersonsSnapshot]. Same dirty-row
  /// conflict policy applies to both upserts and tombstones: a row with a
  /// pending outbox entry is left untouched either way.
  Future<void> applyPersonChanges({
    required List<Person> upserts,
    required List<int> tombstoneIds,
  }) =>
      _db.transaction(() async {
        final dirtyIds = (await (_db.select(_db.personsTable)..where((t) => t.isDirty.equals(true)))
                .get())
            .map((r) => r.id)
            .toSet();

        final toUpsert = upserts.where((p) => !dirtyIds.contains(p.id)).toList();
        if (toUpsert.isNotEmpty) {
          await _db.batch(
            (batch) => batch.insertAllOnConflictUpdate(_db.personsTable, toUpsert.map(_toCompanion).toList()),
          );
        }

        if (tombstoneIds.isNotEmpty) {
          await (_db.update(_db.personsTable)
                ..where((t) => t.id.isIn(tombstoneIds) & t.isDirty.equals(false)))
              .write(const PersonsTableCompanion(isDeleted: Value(true)));
        }
      });

  /// The stored Tier 3 watermark for People (design doc §6, row 6). `0` (the
  /// backend's own "since the beginning" default) when never synced or when
  /// the stored value is somehow unparseable.
  Future<int> getPersonsSyncCursor() async {
    final row = await (_db.select(_db.syncStateTable)..where((t) => t.collection.equals(_syncCollection)))
        .getSingleOrNull();
    return int.tryParse(row?.cursor ?? '') ?? 0;
  }

  /// Persists the new watermark after a successful delta page. Only touches
  /// the `cursor` column — `lastSyncedAt` is written separately by
  /// `SyncService` once the whole pull cycle succeeds.
  Future<void> savePersonsSyncCursor(int cursor) => _db.into(_db.syncStateTable).insertOnConflictUpdate(
        SyncStateTableCompanion.insert(collection: _syncCollection, cursor: Value(cursor.toString())),
      );

  static const _syncCollection = 'persons';

  /// No remote equivalent — single-row upsert after a successful
  /// create/update mutation (design doc §3: mutations go straight to remote
  /// and, on success, upsert into drift so the cache doesn't go stale).
  Future<void> savePerson(Person person) =>
      _db.into(_db.personsTable).insertOnConflictUpdate(_toCompanion(person));

  /// Tier 2 optimistic write (design doc §5): writes [person] into
  /// PersonsTable (marked dirty) and appends one OutboxTable row, in the
  /// same drift transaction. Returns the new outbox row's id so the
  /// repository's `*AndSync` variants can ask `SyncService` to replay this
  /// specific row immediately.
  Future<int> queuePersonMutation({
    required Person person,
    required String operation, // 'create' | 'update'
    required String payloadJson,
  }) =>
      _db.transaction(() async {
        await _db.into(_db.personsTable).insertOnConflictUpdate(
              _toCompanion(person, isDirty: true),
            );
        return _db.into(_db.outboxTable).insert(
              OutboxTableCompanion.insert(
                entityType: 'person',
                entityId: person.id,
                operation: operation,
                payloadJson: payloadJson,
              ),
            );
      });

  /// Called after a queued 'update' syncs successfully: overwrites the
  /// local row with the server-confirmed copy (clears `isDirty`) and
  /// removes the now-done outbox row, in one transaction.
  Future<void> confirmSyncedPerson(Person person, {required int replayedOutboxRowId}) =>
      _db.transaction(() async {
        await _db.into(_db.personsTable).insertOnConflictUpdate(_toCompanion(person));
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();
      });

  /// Tier 2 temp-id reconciliation (design doc §5) after a queued 'create'
  /// syncs. One transaction:
  ///  1. insert the confirmed server row under [realPerson.id]
  ///  2. delete the temp-id row
  ///  3. delete the just-replayed outbox row
  ///  4. self-referential patch: any OTHER still-pending outbox row for
  ///     entityType 'person' whose `entityId` is still [tempId] gets both
  ///     its `entityId` column and the `id` key embedded in its own
  ///     `payloadJson` rewritten to the real id. This is the
  ///     offline-create-then-offline-edit case: two outbox rows both keyed
  ///     to the same temp id before either has synced.
  ///  5. Person's first cross-entity dependent-rewrite step (row 9.9) — the
  ///     doc comment above this method used to defer this "to Events, design
  ///     doc §5"; EventGuest is that first real dependent. Rewrites
  ///     `EventGuestsTable.personId` for any row referencing [tempId], plus
  ///     any still-queued `entityType='eventGuest'` outbox payload's
  ///     `personId` key. `EventGuestsTable` lives in `core/database` like
  ///     every synced table, so this is a Feature → Core access, not a
  ///     Feature → Feature one. Mirrors `EventLocalDataSourceImpl.
  ///     reconcileCreatedEvent`'s own 4th step (decode/patch/re-encode,
  ///     never string-replace).
  ///  6. row 9.14 — a second dependent-rewrite step, this time touching
  ///     **two** FK columns on the same `PersonRelationshipsTable` row
  ///     (`personId` and `relatedPersonId`), since either side of a
  ///     relationship pair could reference an offline-created Person. Also
  ///     rewrites any still-queued `entityType='personRelationship'` outbox
  ///     payload's `personId`/`relatedPersonId` keys — that payload is the
  ///     one queued by `PersonRelationshipRepositoryImpl.createRelationship`,
  ///     shared by both halves of the pair (row 9.13).
  Future<void> reconcileCreatedPerson({
    required int tempId,
    required Person realPerson,
    required int replayedOutboxRowId,
  }) =>
      _db.transaction(() async {
        await _db.into(_db.personsTable).insertOnConflictUpdate(_toCompanion(realPerson));
        await (_db.delete(_db.personsTable)..where((t) => t.id.equals(tempId))).go();
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();

        final pending = await (_db.select(_db.outboxTable)
              ..where((t) => t.entityType.equals('person') & t.entityId.equals(tempId)))
            .get();
        for (final row in pending) {
          final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
          if (payload['id'] == tempId) payload['id'] = realPerson.id;
          await (_db.update(_db.outboxTable)..where((t) => t.id.equals(row.id))).write(
            OutboxTableCompanion(
              entityId: Value(realPerson.id),
              payloadJson: Value(jsonEncode(payload)),
            ),
          );
        }

        await (_db.update(_db.eventGuestsTable)..where((t) => t.personId.equals(tempId)))
            .write(EventGuestsTableCompanion(personId: Value(realPerson.id)));

        final pendingGuestRows = await (_db.select(_db.outboxTable)
              ..where((t) => t.entityType.equals('eventGuest') & t.operation.equals('create')))
            .get();
        for (final row in pendingGuestRows) {
          final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
          if (payload['personId'] != tempId) continue;
          payload['personId'] = realPerson.id;
          await (_db.update(_db.outboxTable)..where((t) => t.id.equals(row.id)))
              .write(OutboxTableCompanion(payloadJson: Value(jsonEncode(payload))));
        }

        await (_db.update(_db.personRelationshipsTable)..where((t) => t.personId.equals(tempId)))
            .write(PersonRelationshipsTableCompanion(personId: Value(realPerson.id)));
        await (_db.update(_db.personRelationshipsTable)..where((t) => t.relatedPersonId.equals(tempId)))
            .write(PersonRelationshipsTableCompanion(relatedPersonId: Value(realPerson.id)));

        final pendingRelationshipRows = await (_db.select(_db.outboxTable)
              ..where((t) => t.entityType.equals('personRelationship') & t.operation.equals('create')))
            .get();
        for (final row in pendingRelationshipRows) {
          final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
          var changed = false;
          if (payload['personId'] == tempId) {
            payload['personId'] = realPerson.id;
            changed = true;
          }
          if (payload['relatedPersonId'] == tempId) {
            payload['relatedPersonId'] = realPerson.id;
            changed = true;
          }
          if (!changed) continue;
          await (_db.update(_db.outboxTable)..where((t) => t.id.equals(row.id)))
              .write(OutboxTableCompanion(payloadJson: Value(jsonEncode(payload))));
        }
      });

  // Duplicated (rather than shared via a generic helper) because
  // `select()`/`SimpleSelectStatement` and `selectOnly()`/`SelectOnly` have
  // different `.where()` signatures in drift — fighting that generically
  // costs more than these six lines twice.
  void _applySelectFilters(
    SimpleSelectStatement<$PersonsTableTable, PersonsTableData> q, {
    int? groupId,
    int? subGroupId,
    int? governorateId,
    int? cityId,
    int? neighborhoodId,
    String? search,
  }) {
    if (groupId != null) q.where((t) => t.groupId.equals(groupId));
    if (subGroupId != null) q.where((t) => t.subGroupId.equals(subGroupId));
    if (governorateId != null) q.where((t) => t.governorateId.equals(governorateId));
    if (cityId != null) q.where((t) => t.cityId.equals(cityId));
    if (neighborhoodId != null) q.where((t) => t.neighborhoodId.equals(neighborhoodId));
    if (search != null && search.isNotEmpty) {
      final pattern = '%$search%';
      q.where(
        (t) => t.name.like(pattern) | t.phoneNumber.like(pattern) | t.phoneNumber2.like(pattern),
      );
    }
  }

  void _applySelectOnlyFilters(
    JoinedSelectStatement<$PersonsTableTable, PersonsTableData> q, {
    int? groupId,
    int? subGroupId,
    int? governorateId,
    int? cityId,
    int? neighborhoodId,
    String? search,
  }) {
    final t = _db.personsTable;
    if (groupId != null) q.where(t.groupId.equals(groupId));
    if (subGroupId != null) q.where(t.subGroupId.equals(subGroupId));
    if (governorateId != null) q.where(t.governorateId.equals(governorateId));
    if (cityId != null) q.where(t.cityId.equals(cityId));
    if (neighborhoodId != null) q.where(t.neighborhoodId.equals(neighborhoodId));
    if (search != null && search.isNotEmpty) {
      final pattern = '%$search%';
      q.where(t.name.like(pattern) | t.phoneNumber.like(pattern) | t.phoneNumber2.like(pattern));
    }
  }

  Person _toEntity(PersonsTableData row) => Person(
        id: row.id,
        name: row.name,
        phoneNumber: row.phoneNumber,
        phoneNumber2: row.phoneNumber2,
        gender: Gender.fromWire(row.gender),
        groupId: row.groupId,
        groupName: row.groupName,
        subGroupId: row.subGroupId,
        subGroupName: row.subGroupName,
        governorateId: row.governorateId,
        governorateName: row.governorateName,
        cityId: row.cityId,
        cityName: row.cityName,
        neighborhoodId: row.neighborhoodId,
        neighborhoodName: row.neighborhoodName,
        primaryPhotoUrl: row.primaryPhotoUrl,
        notes: row.notes,
        hasReciprocityHistory: row.hasReciprocityHistory,
        updatedAt: row.updatedAt,
      );

  PersonsTableCompanion _toCompanion(Person person, {bool isDirty = false}) =>
      PersonsTableCompanion.insert(
        id: Value(person.id),
        name: person.name,
        phoneNumber: Value(person.phoneNumber),
        phoneNumber2: Value(person.phoneNumber2),
        gender: person.gender.toWire(),
        groupId: person.groupId,
        groupName: person.groupName,
        subGroupId: Value(person.subGroupId),
        subGroupName: Value(person.subGroupName),
        governorateId: person.governorateId,
        governorateName: person.governorateName,
        cityId: Value(person.cityId),
        cityName: Value(person.cityName),
        neighborhoodId: Value(person.neighborhoodId),
        neighborhoodName: Value(person.neighborhoodName),
        primaryPhotoUrl: Value(person.primaryPhotoUrl),
        notes: Value(person.notes),
        hasReciprocityHistory: Value(person.hasReciprocityHistory),
        // `updatedAt` comes from the server (design doc §6, row 5/6); still
        // nullable because a locally-created draft (Tier 2 optimistic
        // create, not yet synced) has none. Never soft-deleted here.
        // `isDirty` defaults to false (a row that came from a confirmed
        // remote round trip) — callers queuing a Tier 2 optimistic write
        // pass `isDirty: true` explicitly.
        updatedAt: Value(person.updatedAt),
        isDeleted: const Value(false),
        isDirty: Value(isDirty),
      );
}
