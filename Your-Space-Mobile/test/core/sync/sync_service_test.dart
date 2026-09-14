import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/network/connectivity_helper.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/collection_puller.dart';
import 'package:your_space_mobile/core/sync/outbox_replayer.dart';
import 'package:your_space_mobile/core/sync/sync_service.dart';

class MockConnectivityHelper extends Mock implements ConnectivityHelper {}

/// Configurable fake `CollectionPuller` — records call count and returns a
/// caller-controlled result, so `pullAll()`/watermark bookkeeping can be
/// tested without depending on a real feature's repository.
class FakeCollectionPuller implements CollectionPuller {
  FakeCollectionPuller({this.result = const Right(unit)});

  Either<Failure, Unit> result;
  int callCount = 0;

  @override
  String get collection => 'things';

  @override
  Future<Either<Failure, Unit>> pull() async {
    callCount++;
    return result;
  }
}

/// Configurable, generic replayer used to test `SyncService` in isolation
/// from any real feature. Records every row it's asked to replay (in call
/// order) and, optionally, applies a caller-supplied DB side effect on
/// success — used to simulate the temp-id reconciliation staleness case
/// without depending on People's real reconciliation logic.
class FakeOutboxReplayer implements OutboxReplayer {
  FakeOutboxReplayer(this._db, {this.onSuccess});

  final AppDatabase _db;
  final Future<void> Function(OutboxTableData row)? onSuccess;
  final List<OutboxTableData> calls = [];
  final Map<int, Failure> failuresByRowId = {};

  @override
  String get entityType => 'thing';

  @override
  Future<Either<Failure, Object?>> replay(OutboxTableData row) async {
    calls.add(row);
    final failure = failuresByRowId[row.id];
    if (failure != null) return Left(failure);
    if (onSuccess != null) await onSuccess!(row);
    // Fulfilling OutboxReplayer's contract (see its doc comment): a
    // successful replay must resolve the row itself — SyncService never
    // deletes on success.
    await (_db.delete(_db.outboxTable)..where((t) => t.id.equals(row.id))).go();
    return const Right(null);
  }
}

Future<int> _seedRow(
  AppDatabase db, {
  required int entityId,
  String operation = 'create',
  String payloadJson = '{}',
  int retryCount = 0,
  DateTime? lastAttemptAt,
  DateTime? createdAt,
}) =>
    db.into(db.outboxTable).insert(
          OutboxTableCompanion.insert(
            entityType: 'thing',
            entityId: entityId,
            operation: operation,
            payloadJson: payloadJson,
            retryCount: Value(retryCount),
            lastAttemptAt: Value(lastAttemptAt),
            createdAt: Value(createdAt ?? DateTime.now()),
          ),
        );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late MockConnectivityHelper connectivity;
  late StreamController<bool> connectivityController;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    connectivity = MockConnectivityHelper();
    connectivityController = StreamController<bool>.broadcast();
    when(() => connectivity.connectivityStream).thenAnswer((_) => connectivityController.stream);
    when(() => connectivity.isConnected()).thenAnswer((_) async => false); // no cold-start replay by default
  });

  tearDown(() async {
    await connectivityController.close();
    await db.close();
  });

  // Every construction goes through here so the WidgetsBindingObserver
  // registration is always cleaned up — otherwise stale observers from
  // earlier tests would receive later tests' lifecycle events and touch an
  // already-closed db.
  SyncService createService({
    List<OutboxReplayer> replayers = const [],
    List<CollectionPuller> pullers = const [],
  }) {
    final service = SyncService(db, connectivity, replayers, pullers);
    addTearDown(service.dispose);
    return service;
  }

  test('a never-attempted row (lastAttemptAt null) is due immediately', () async {
    await _seedRow(db, entityId: 1);
    final replayer = FakeOutboxReplayer(db);
    final service = createService(replayers: [replayer]);

    await service.replayAll();

    expect(replayer.calls, hasLength(1));
  });

  test('backoff thresholds: a row is not due until its schedule slot has elapsed', () async {
    // retryCount 1 -> due after 5s. 4s ago is not due; 6s ago is due.
    await _seedRow(db, entityId: 1, retryCount: 1, lastAttemptAt: DateTime.now().subtract(const Duration(seconds: 4)));
    await _seedRow(db, entityId: 2, retryCount: 1, lastAttemptAt: DateTime.now().subtract(const Duration(seconds: 6)));
    final replayer = FakeOutboxReplayer(db);
    final service = createService(replayers: [replayer]);

    await service.replayAll();

    expect(replayer.calls.map((r) => r.entityId), [2]);
  });

  test('a row at the max retry count is held and never selected', () async {
    await _seedRow(db, entityId: 1, retryCount: 6, lastAttemptAt: DateTime.now().subtract(const Duration(days: 1)));
    final replayer = FakeOutboxReplayer(db);
    final service = createService(replayers: [replayer]);

    await service.replayAll();

    expect(replayer.calls, isEmpty);
  });

  test('replayAll processes due rows oldest-first', () async {
    await _seedRow(db, entityId: 2, createdAt: DateTime(2026, 1, 2));
    await _seedRow(db, entityId: 1, createdAt: DateTime(2026, 1, 1));
    await _seedRow(db, entityId: 3, createdAt: DateTime(2026, 1, 3));
    final replayer = FakeOutboxReplayer(db);
    final service = createService(replayers: [replayer]);

    await service.replayAll();

    expect(replayer.calls.map((r) => r.entityId), [1, 2, 3]);
  });

  test('a failure increments retryCount and stamps lastAttemptAt/lastError, without dropping the row', () async {
    final rowId = await _seedRow(db, entityId: 1);
    final replayer = FakeOutboxReplayer(db)..failuresByRowId[rowId] = const NetworkFailure();
    final service = createService(replayers: [replayer]);

    await service.replayAll();

    final row = await (db.select(db.outboxTable)..where((t) => t.id.equals(rowId))).getSingle();
    expect(row.retryCount, 1);
    expect(row.lastAttemptAt, isNotNull);
    expect(row.lastError, isNotNull);
  });

  test(
      'staleness regression: a later row referencing the same entityId sees the reconciliation patch from an '
      'earlier row in the SAME replayAll() pass, not a stale snapshot', () async {
    const tempId = -1;
    const realId = 999;
    await _seedRow(db, entityId: tempId, operation: 'create', createdAt: DateTime(2026, 1, 1));
    await _seedRow(db, entityId: tempId, operation: 'update', createdAt: DateTime(2026, 1, 2));

    final replayer = FakeOutboxReplayer(
      db,
      onSuccess: (row) async {
        if (row.operation != 'create') return;
        // Mimic PersonLocalDataSourceImpl.reconcileCreatedPerson's
        // self-referential patch: rewrite any other pending row still
        // referencing the temp id.
        await (db.update(db.outboxTable)..where((t) => t.entityId.equals(tempId) & t.id.equals(row.id).not()))
            .write(const OutboxTableCompanion(entityId: Value(realId)));
      },
    );
    final service = createService(replayers: [replayer]);

    await service.replayAll();

    expect(replayer.calls, hasLength(2));
    expect(replayer.calls[0].entityId, tempId); // the create, seen before reconciliation
    expect(replayer.calls[1].entityId, realId); // the update, seen AFTER reconciliation patched it
  });

  test('connectivity regained triggers a background replayAll() and pullAll()', () async {
    await _seedRow(db, entityId: 1);
    final replayer = FakeOutboxReplayer(db);
    final puller = FakeCollectionPuller();
    createService(replayers: [replayer], pullers: [puller]);

    connectivityController.add(true);
    await pumpEventQueue();

    expect(replayer.calls, hasLength(1));
    expect(puller.callCount, 1);
  });

  test('a cold-start check that finds connectivity already up also triggers a replay and pull', () async {
    when(() => connectivity.isConnected()).thenAnswer((_) async => true);
    await _seedRow(db, entityId: 1);
    final replayer = FakeOutboxReplayer(db);
    final puller = FakeCollectionPuller();
    createService(replayers: [replayer], pullers: [puller]);

    await pumpEventQueue();

    expect(replayer.calls, hasLength(1));
    expect(puller.callCount, 1);
  });

  group('pullAll', () {
    test('calls every registered puller and writes SyncStateTable.lastSyncedAt on success', () async {
      final puller = FakeCollectionPuller();
      final service = createService(pullers: [puller]);

      await service.pullAll();

      expect(puller.callCount, 1);
      final row =
          await (db.select(db.syncStateTable)..where((t) => t.collection.equals('things'))).getSingle();
      expect(row.lastSyncedAt, isNotNull);
    });

    test('leaves SyncStateTable untouched on a failing pull', () async {
      final puller = FakeCollectionPuller(result: const Left(NetworkFailure()));
      final service = createService(pullers: [puller]);

      await service.pullAll();

      expect(puller.callCount, 1);
      final row = await (db.select(db.syncStateTable)..where((t) => t.collection.equals('things')))
          .getSingleOrNull();
      expect(row, isNull);
    });
  });

  group('app lifecycle', () {
    test('resuming triggers pullAll() and replayAll()', () async {
      await _seedRow(db, entityId: 1);
      final replayer = FakeOutboxReplayer(db);
      final puller = FakeCollectionPuller();
      final service = createService(replayers: [replayer], pullers: [puller]);

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(replayer.calls, hasLength(1));
      expect(puller.callCount, 1);
    });

    test('a non-resumed state does not trigger a pull or replay', () async {
      await _seedRow(db, entityId: 1);
      final replayer = FakeOutboxReplayer(db);
      final puller = FakeCollectionPuller();
      final service = createService(replayers: [replayer], pullers: [puller]);

      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await pumpEventQueue();

      expect(replayer.calls, isEmpty);
      expect(puller.callCount, 0);
    });
  });

  group('replayRow', () {
    test('bypasses the backoff-due check and replays immediately', () async {
      final rowId = await _seedRow(
        db,
        entityId: 1,
        retryCount: 1,
        lastAttemptAt: DateTime.now(), // would not be due for 5s under the schedule
      );
      final replayer = FakeOutboxReplayer(db);
      final service = createService(replayers: [replayer]);

      final result = await service.replayRow(rowId);

      expect(result, const Right<Failure, Object?>(null));
      expect(replayer.calls, hasLength(1));
    });

    test('no-ops safely when the row no longer exists', () async {
      final replayer = FakeOutboxReplayer(db);
      final service = createService(replayers: [replayer]);

      final result = await service.replayRow(12345);

      expect(result, const Right<Failure, Object?>(null));
      expect(replayer.calls, isEmpty);
    });
  });
}
