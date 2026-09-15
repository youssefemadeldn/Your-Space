import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/features/events/domain/entities/event.dart';

/// Drift-backed local store for Events — the Tier 1 read path (CLAUDE.md
/// Architecture rule 7), mirrors `GroupLocalDataSourceImpl`. Does not
/// implement `BaseEventDataSource`: it's typed concretely in
/// `EventRepositoryImpl` so its `save*`/`queue*`/`reconcile*` write methods
/// (no direct remote equivalent) are reachable.
@Named('local')
@lazySingleton
class EventLocalDataSourceImpl {
  final AppDatabase _db;

  EventLocalDataSourceImpl(this._db);

  /// Reactive read path — the local table holds the user's entire owned
  /// collection (design doc §3); `limit` grows as `loadMore()` is called.
  Stream<List<Event>> watchEvents({String? search, required int limit}) {
    final query = _db.select(_db.eventsTable)
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.eventDate)])
      ..limit(limit);
    if (search != null && search.isNotEmpty) {
      final pattern = '%$search%';
      query.where((t) => t.name.like(pattern) | t.nameAr.like(pattern));
    }
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  /// One-shot exact count for the same filter set — backs `hasNextPage`
  /// without a `length == limit` heuristic.
  Future<int> countEvents({String? search}) {
    final countExp = _db.eventsTable.id.count();
    final query = _db.selectOnly(_db.eventsTable)..addColumns([countExp]);
    query.where(_db.eventsTable.isDeleted.equals(false));
    if (search != null && search.isNotEmpty) {
      final pattern = '%$search%';
      query.where(_db.eventsTable.name.like(pattern) | _db.eventsTable.nameAr.like(pattern));
    }
    return query.map((row) => row.read(countExp) ?? 0).getSingle();
  }

  /// Tier 1 upsert, no tombstoning — kept as a documented primitive for a
  /// future caller that wants a plain bulk replace. `refreshEvents()` (Tier
  /// 3) uses `applyEventChanges` instead once the real delta pull lands.
  Future<void> saveEvents(List<Event> events) => _db.batch(
        (batch) => batch.insertAllOnConflictUpdate(
          _db.eventsTable,
          events.map(_toCompanion).toList(),
        ),
      );

  /// No remote equivalent — single-row upsert after a successful
  /// create/update mutation. Transitional Tier 1 write path used by
  /// `EventRepositoryImpl.createEvent`/`updateEvent` until row 9.3 moves
  /// them to the outbox.
  Future<void> saveEvent(Event event) =>
      _db.into(_db.eventsTable).insertOnConflictUpdate(_toCompanion(event));

  /// No remote equivalent — hard-removes the local row. Kept as a documented
  /// primitive, mirrors `CityLocalDataSourceImpl.deleteCityLocal`.
  Future<void> deleteEventLocal(int id) =>
      (_db.delete(_db.eventsTable)..where((t) => t.id.equals(id))).go();

  /// Tier 2 optimistic write (design doc §5): writes [event] into
  /// EventsTable (marked dirty) and appends one OutboxTable row, in the same
  /// drift transaction. Mirrors `GroupLocalDataSourceImpl.queueGroupMutation`
  /// — Event has no delete flow in the mobile UI yet, so only
  /// `'create'`/`'update'` are handled (same shape as Group).
  Future<int> queueEventMutation({
    required Event event,
    required String operation, // 'create' | 'update'
    required String payloadJson,
  }) =>
      _db.transaction(() async {
        await _db.into(_db.eventsTable).insertOnConflictUpdate(
              _toCompanion(event, isDirty: true),
            );
        return _db.into(_db.outboxTable).insert(
              OutboxTableCompanion.insert(
                entityType: 'event',
                entityId: event.id,
                operation: operation,
                payloadJson: payloadJson,
              ),
            );
      });

  /// Called after a queued 'update' syncs successfully: overwrites the
  /// local row with the server-confirmed copy (clears `isDirty`) and
  /// removes the now-done outbox row, in one transaction.
  Future<void> confirmSyncedEvent(Event event, {required int replayedOutboxRowId}) =>
      _db.transaction(() async {
        await _db.into(_db.eventsTable).insertOnConflictUpdate(_toCompanion(event));
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();
      });

  /// Tier 2 temp-id reconciliation (design doc §5) after a queued 'create'
  /// syncs. One transaction: insert the confirmed server row under
  /// [realEvent].id, delete the temp-id row, delete the just-replayed
  /// outbox row. No dependent-rewrite step here — that's added when
  /// EventGuest's own Tier 2 step (row 9.9) makes Event a real sync parent
  /// for the first time (see that step's own doc comment on this method).
  Future<void> reconcileCreatedEvent({
    required int tempId,
    required Event realEvent,
    required int replayedOutboxRowId,
  }) =>
      _db.transaction(() async {
        await _db.into(_db.eventsTable).insertOnConflictUpdate(_toCompanion(realEvent));
        await (_db.delete(_db.eventsTable)..where((t) => t.id.equals(tempId))).go();
        await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(replayedOutboxRowId))).go();
      });

  /// Tier 3 "full refetch as delta" (design doc §6) — interim mode until the
  /// backend's real delta endpoint lands later in this same sprint (row
  /// 9.5/9.6): fetches the complete owned collection and diffs it against
  /// local drift by id in one transaction. Mirrors
  /// `CityLocalDataSourceImpl.applyCitiesSnapshot`. Superseded in-place by
  /// `applyEventChanges` once `refreshEvents()` switches to the real cursor
  /// loop — kept only as long as that switch hasn't landed yet.
  Future<void> applyEventsSnapshot(List<Event> serverEvents) => _db.transaction(() async {
        final dirtyIds = (await (_db.select(_db.eventsTable)..where((t) => t.isDirty.equals(true))).get())
            .map((r) => r.id)
            .toSet();
        final toUpsert = serverEvents.where((e) => !dirtyIds.contains(e.id)).toList();
        await _db.batch(
          (batch) => batch.insertAllOnConflictUpdate(_db.eventsTable, toUpsert.map(_toCompanion).toList()),
        );

        final serverIds = serverEvents.map((e) => e.id).toSet();
        await (_db.update(_db.eventsTable)
              ..where(
                (t) => t.id.isBiggerThanValue(0) & t.isDirty.equals(false) & t.id.isNotIn(serverIds),
              ))
            .write(const EventsTableCompanion(isDeleted: Value(true)));
      });

  Event _toEntity(EventsTableData row) => Event(
        id: row.id,
        name: row.name,
        nameAr: row.nameAr,
        eventDate: row.eventDate,
        notes: row.notes,
        totalGuestCount: row.totalGuestCount,
      );

  EventsTableCompanion _toCompanion(Event event, {bool isDirty = false}) => EventsTableCompanion.insert(
        id: Value(event.id),
        name: event.name,
        nameAr: Value(event.nameAr),
        eventDate: Value(event.eventDate),
        notes: Value(event.notes),
        totalGuestCount: Value(event.totalGuestCount),
        isDeleted: const Value(false),
        isDirty: Value(isDirty),
      );
}
