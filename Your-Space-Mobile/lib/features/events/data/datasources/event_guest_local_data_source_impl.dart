import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest.dart';
import 'package:your_space_mobile/features/events/domain/entities/event_guest_status.dart';
import 'package:your_space_mobile/core/entities/invite_method.dart';

/// Drift-backed local store for EventGuests — the Tier 1 read path (CLAUDE.md
/// Architecture rule 7), mirrors `EventLocalDataSourceImpl`. Does not
/// implement `BaseEventGuestDataSource`: it's typed concretely in
/// `EventGuestRepositoryImpl` so its `save*`/`queue*`/`reconcile*` write
/// methods (no direct remote equivalent) are reachable.
@Named('local')
@lazySingleton
class EventGuestLocalDataSourceImpl {
  final AppDatabase _db;

  EventGuestLocalDataSourceImpl(this._db);

  /// Reactive read path, scoped to one parent event — the local table holds
  /// *all* the user's event guests across every event; filtering by
  /// `eventId`/`groupId`/`status` is a plain `WHERE` clause (design doc §3).
  Stream<List<EventGuest>> watchEventGuests({
    required int eventId,
    int? groupId,
    EventGuestStatus? status,
    required int limit,
  }) {
    final query = _db.select(_db.eventGuestsTable)
      ..where((t) => t.isDeleted.equals(false) & t.eventId.equals(eventId))
      ..orderBy([(t) => OrderingTerm.asc(t.personName)])
      ..limit(limit);
    if (groupId != null) {
      query.where((t) => t.groupId.equals(groupId));
    }
    if (status != null) {
      query.where((t) => t.status.equals(status.toWire()));
    }
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  /// Parent-agnostic reactive read — feeds the Tier 3 full-refetch diff and
  /// any future flat guest picker.
  Stream<List<EventGuest>> watchAllEventGuests({required int limit}) {
    final query = _db.select(_db.eventGuestsTable)
      ..where((t) => t.isDeleted.equals(false))
      ..limit(limit);
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  /// One-shot exact count for the same filter set — backs `hasNextPage`
  /// without a `length == limit` heuristic.
  Future<int> countEventGuests({required int eventId, int? groupId, EventGuestStatus? status}) {
    final countExp = _db.eventGuestsTable.id.count();
    final query = _db.selectOnly(_db.eventGuestsTable)..addColumns([countExp]);
    query.where(_db.eventGuestsTable.isDeleted.equals(false) & _db.eventGuestsTable.eventId.equals(eventId));
    if (groupId != null) {
      query.where(_db.eventGuestsTable.groupId.equals(groupId));
    }
    if (status != null) {
      query.where(_db.eventGuestsTable.status.equals(status.toWire()));
    }
    return query.map((row) => row.read(countExp) ?? 0).getSingle();
  }

  /// Tier 1 upsert, no tombstoning — kept as a documented primitive for a
  /// future caller that wants a plain bulk replace. `refreshEventGuests()`
  /// (Tier 3, row 9.10) uses `applyEventGuestsSnapshot` instead.
  Future<void> saveEventGuests(List<EventGuest> guests) => _db.batch(
        (batch) => batch.insertAllOnConflictUpdate(
          _db.eventGuestsTable,
          guests.map(_toCompanion).toList(),
        ),
      );

  /// No remote equivalent — hard-removes the local row. Kept as a documented
  /// primitive, mirrors `EventLocalDataSourceImpl.deleteEventLocal`.
  Future<void> deleteEventGuestLocal(int id) =>
      (_db.delete(_db.eventGuestsTable)..where((t) => t.id.equals(id))).go();

  /// Tier 2 optimistic write (design doc §5): writes [guest] into
  /// EventGuestsTable (marked dirty) and appends one OutboxTable row, in the
  /// same drift transaction. `operation` is `'create'` for a bulk-add
  /// result or `'update'` for a status transition (invite/skip/revert) — see
  /// the row 9 cross-cutting "outbox vocabulary extension" decision: bulk-add
  /// resolves to concrete persons client-side first, then queues one row per
  /// resulting guest, so there is no bulk-shaped outbox operation.
  Future<int> queueEventGuestMutation({
    required EventGuest guest,
    required String operation, // 'create' | 'update'
    required String payloadJson,
  }) =>
      _db.transaction(() async {
        await _db.into(_db.eventGuestsTable).insertOnConflictUpdate(
              _toCompanion(guest, isDirty: true),
            );
        return _db.into(_db.outboxTable).insert(
              OutboxTableCompanion.insert(
                entityType: 'eventGuest',
                entityId: guest.id,
                operation: operation,
                payloadJson: payloadJson,
              ),
            );
      });

  /// Called after a queued 'update' syncs successfully: overwrites the
  /// local row with the server-confirmed copy (clears `isDirty`) and
  /// removes the now-done outbox row, in one transaction.
  Future<void> confirmSyncedEventGuest(EventGuest guest, {required int replayedOutboxRowId}) =>
      _db.transaction(() async {
        await _db.into(_db.eventGuestsTable).insertOnConflictUpdate(_toCompanion(guest));
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();
      });

  /// Tier 2 temp-id reconciliation (design doc §5) after a queued 'create'
  /// syncs. One transaction: insert the confirmed server row under
  /// [realGuest].id, delete the temp-id row, delete the just-replayed
  /// outbox row. EventGuest is always a dependent, never a sync parent — no
  /// 4th rewrite step here.
  Future<void> reconcileCreatedEventGuest({
    required int tempId,
    required EventGuest realGuest,
    required int replayedOutboxRowId,
  }) =>
      _db.transaction(() async {
        await _db.into(_db.eventGuestsTable).insertOnConflictUpdate(_toCompanion(realGuest));
        await (_db.delete(_db.eventGuestsTable)..where((t) => t.id.equals(tempId))).go();
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();
      });

  /// Tier 2 optimistic delete (design doc §5) — mirrors
  /// `CityLocalDataSourceImpl.queueDeletedCity`'s two-path shape exactly.
  /// [payloadJson] carries `eventId` — `EventGuestOutboxReplayer` needs it
  /// for `BaseEventGuestDataSource.removeGuest`'s nested route, and it isn't
  /// derivable from [id] alone.
  Future<void> queueDeletedEventGuest(int id, {required String payloadJson}) => _db.transaction(() async {
        if (id < 0) {
          await (_db.delete(_db.eventGuestsTable)..where((t) => t.id.equals(id))).go();
          await (_db.delete(_db.outboxTable)
                ..where((t) => t.entityType.equals('eventGuest') & t.entityId.equals(id)))
              .go();
          return;
        }
        await (_db.update(_db.eventGuestsTable)..where((t) => t.id.equals(id)))
            .write(const EventGuestsTableCompanion(isDeleted: Value(true), isDirty: Value(true)));
        await _db.into(_db.outboxTable).insert(
              OutboxTableCompanion.insert(
                entityType: 'eventGuest',
                entityId: id,
                operation: 'delete',
                payloadJson: payloadJson,
              ),
            );
      });

  /// Called after a queued 'delete' syncs successfully: hard-removes the
  /// local row and the outbox row, in one transaction.
  Future<void> confirmDeletedEventGuest(int id, {required int replayedOutboxRowId}) =>
      _db.transaction(() async {
        await (_db.delete(_db.eventGuestsTable)..where((t) => t.id.equals(id))).go();
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();
      });

  /// Tier 3 "full refetch as delta" (design doc §6) — **permanent**, not an
  /// interim stage (row 9 cross-cutting decision: EventGuest is
  /// hard-delete-only, so no tombstone stream is ever possible without a
  /// soft-delete column). Fetches the complete owned collection across every
  /// event and diffs it against local drift by id in one transaction, same
  /// shape as `EventLocalDataSourceImpl.applyEventsSnapshot`.
  Future<void> applyEventGuestsSnapshot(List<EventGuest> serverGuests) => _db.transaction(() async {
        final dirtyIds =
            (await (_db.select(_db.eventGuestsTable)..where((t) => t.isDirty.equals(true))).get())
                .map((r) => r.id)
                .toSet();
        final toUpsert = serverGuests.where((g) => !dirtyIds.contains(g.id)).toList();
        await _db.batch(
          (batch) =>
              batch.insertAllOnConflictUpdate(_db.eventGuestsTable, toUpsert.map(_toCompanion).toList()),
        );

        final serverIds = serverGuests.map((g) => g.id).toSet();
        await (_db.update(_db.eventGuestsTable)
              ..where(
                (t) => t.id.isBiggerThanValue(0) & t.isDirty.equals(false) & t.id.isNotIn(serverIds),
              ))
            .write(const EventGuestsTableCompanion(isDeleted: Value(true)));
      });

  EventGuest _toEntity(EventGuestsTableData row) => EventGuest(
        id: row.id,
        eventId: row.eventId,
        personId: row.personId,
        personName: row.personName,
        personPhoneNumber: row.personPhoneNumber,
        groupId: row.groupId,
        groupName: row.groupName,
        status: EventGuestStatus.fromWire(row.status),
        inviteMethod: row.inviteMethod == null ? null : InviteMethod.fromWire(row.inviteMethod!),
        invitedAt: row.invitedAt,
      );

  EventGuestsTableCompanion _toCompanion(EventGuest guest, {bool isDirty = false}) =>
      EventGuestsTableCompanion.insert(
        id: Value(guest.id),
        eventId: guest.eventId,
        personId: guest.personId,
        personName: guest.personName,
        personPhoneNumber: Value(guest.personPhoneNumber),
        groupId: guest.groupId,
        groupName: guest.groupName,
        status: guest.status.toWire(),
        inviteMethod: Value(guest.inviteMethod?.toWire()),
        invitedAt: Value(guest.invitedAt),
        isDeleted: const Value(false),
        isDirty: Value(isDirty),
      );
}
