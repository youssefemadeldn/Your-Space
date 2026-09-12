import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/network/connectivity_helper.dart';
import 'package:your_space_mobile/core/network/failure.dart';

import 'collection_puller.dart';
import 'outbox_replayer.dart';

/// Background push/pull orchestrator (Tier 2 outbox + Tier 3 pull, design
/// doc §5/§6). Never provided to a `BlocProvider` and never awaited from a
/// cubit (CLAUDE.md DI-scopes table) — repositories may await [replayRow]
/// directly (data layer, not presentation) for an immediate "sync this one
/// now" attempt; everything else happens in the background, triggered by
/// connectivity regained, cold start, app foreground/resume, a 15-minute
/// foreground floor timer, or manual pull-to-refresh (which calls a
/// repository's `refreshPersons()`-style method directly, not through here).
///
/// Established with no prior precedent in this codebase (no existing
/// self-initializing singleton listener, no `@PostConstruct` usage) — see
/// `main.dart`'s eager `getIt<SyncService>()` warm-up call for how it gets
/// started.
@lazySingleton
class SyncService with WidgetsBindingObserver {
  final AppDatabase _db;
  final ConnectivityHelper _connectivity;
  final Map<String, OutboxReplayer> _replayers;
  final Map<String, CollectionPuller> _pullers;
  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _foregroundTimer;
  bool _isReplaying = false;

  // Exponential backoff, capped (design doc §5): 5s -> 15s -> 60s -> 5min ->
  // 15min, then held until `_maxRetries` is hit.
  static const _backoffSchedule = [
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 60),
    Duration(minutes: 5),
    Duration(minutes: 15),
  ];
  static const _maxRetries = 6;

  // Design doc §6 "when SyncService runs": app foreground is a floor, not a
  // ceiling — a resume always pulls immediately, then this timer keeps
  // pulling every 15 minutes for as long as the app stays foregrounded.
  static const _foregroundPullInterval = Duration(minutes: 15);

  SyncService(
    this._db,
    this._connectivity,
    List<OutboxReplayer> replayers,
    List<CollectionPuller> pullers,
  )   : _replayers = {for (final replayer in replayers) replayer.entityType: replayer},
        _pullers = {for (final puller in pullers) puller.collection: puller} {
    WidgetsBinding.instance.addObserver(this);
    _connectivitySubscription = _connectivity.connectivityStream.listen((connected) {
      if (connected) {
        replayAll();
        pullAll();
      }
    });
    // Cold-start check: a connectivity *edge* never fires if the device is
    // already online when the app launches.
    _connectivity.isConnected().then((connected) {
      if (connected) {
        replayAll();
        pullAll();
      }
    });
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      _startForegroundTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      pullAll();
      replayAll();
      _startForegroundTimer();
    } else {
      _foregroundTimer?.cancel();
    }
  }

  void _startForegroundTimer() {
    _foregroundTimer?.cancel();
    _foregroundTimer = Timer.periodic(_foregroundPullInterval, (_) {
      pullAll();
      replayAll();
    });
  }

  /// Background, fire-and-forget — runs every registered puller once and
  /// records the watermark on success. A failed pull leaves the previous
  /// `SyncStateTable` row untouched (no retry/backoff bookkeeping for pulls;
  /// unlike the outbox, a failed pull just waits for the next trigger).
  Future<void> pullAll() async {
    for (final puller in _pullers.values) {
      final result = await puller.pull();
      if (result.isRight()) {
        await _recordSyncedAt(puller.collection);
      }
    }
  }

  Future<void> _recordSyncedAt(String collection) => _db.into(_db.syncStateTable).insertOnConflictUpdate(
        SyncStateTableCompanion.insert(
          collection: collection,
          lastSyncedAt: Value(DateTime.now()),
        ),
      );

  /// Background, fire-and-forget — the constructor's own connectivity
  /// listener calls this; nothing else should await it (see class doc).
  ///
  /// Re-queries due rows one at a time rather than snapshotting a list up
  /// front: if an earlier row in this pass is a 'create' that gets
  /// reconciled, a later row referencing the same temp id must see the
  /// *patched* entityId/payload, not a stale in-memory copy from before
  /// reconciliation.
  ///
  /// [OutboxReplayer.replay] is contractually responsible for resolving a
  /// row it succeeds on (deleting/confirming it) — a replayer that returns
  /// `Right` without doing so leaves the row perpetually "due" (nothing here
  /// ever deletes rows on success). `_settledRowIds` is a defensive guard
  /// against exactly that bug: if the same row id comes back due twice in
  /// one pass, something didn't resolve it, so this stops instead of
  /// looping forever.
  Future<void> replayAll() async {
    if (_isReplaying) return;
    _isReplaying = true;
    final settledRowIds = <int>{};
    try {
      while (true) {
        final next = await _dueRows(limit: 1);
        if (next.isEmpty) break;
        final row = next.first;
        if (!settledRowIds.add(row.id)) break;
        await _attempt(row);
      }
    } finally {
      _isReplaying = false;
    }
  }

  /// Replays exactly one row right now, ignoring the backoff-due check —
  /// this is an explicit, freshly-queued attempt, not a scheduled retry.
  /// This is the seam a repository's `*AndSync` methods await directly
  /// (data layer, not a cubit).
  Future<Either<Failure, Object?>> replayRow(int outboxRowId) async {
    final row =
        await (_db.select(_db.outboxTable)..where((t) => t.id.equals(outboxRowId))).getSingleOrNull();
    if (row == null) return const Right(null); // already handled elsewhere
    return _attempt(row);
  }

  Future<Either<Failure, Object?>> _attempt(OutboxTableData row) async {
    final replayer = _replayers[row.entityType];
    if (replayer == null) {
      return Left(UnexpectedFailure(message: 'No OutboxReplayer for ${row.entityType}'));
    }
    final result = await replayer.replay(row);
    await result.fold((failure) => _recordFailure(row, failure), (_) async {});
    return result;
  }

  Future<void> _recordFailure(OutboxTableData row, Failure failure) =>
      (_db.update(_db.outboxTable)..where((t) => t.id.equals(row.id))).write(
        OutboxTableCompanion(
          retryCount: Value(row.retryCount + 1),
          lastAttemptAt: Value(DateTime.now()),
          lastError: Value(failure.toString()),
        ),
      );

  Future<List<OutboxTableData>> _dueRows({required int limit}) async {
    final rows =
        await (_db.select(_db.outboxTable)..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();
    final now = DateTime.now();
    return rows.where((row) => _isDue(row, now)).take(limit).toList();
  }

  bool _isDue(OutboxTableData row, DateTime now) {
    if (row.retryCount >= _maxRetries) return false; // held per design doc §5
    if (row.lastAttemptAt == null) return true;
    final index = (row.retryCount - 1).clamp(0, _backoffSchedule.length - 1);
    return now.difference(row.lastAttemptAt!) >= _backoffSchedule[index];
  }

  @disposeMethod
  void dispose() {
    _connectivitySubscription?.cancel();
    _foregroundTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
