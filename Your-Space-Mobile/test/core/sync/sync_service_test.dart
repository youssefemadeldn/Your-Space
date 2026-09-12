import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/network/connectivity_helper.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/outbox_replayer.dart';
import 'package:your_space_mobile/core/sync/sync_service.dart';

class MockConnectivityHelper extends Mock implements ConnectivityHelper {}

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

  test('a never-attempted row (lastAttemptAt null) is due immediately', () async {
    await _seedRow(db, entityId: 1);
    final replayer = FakeOutboxReplayer(db);
    final service = SyncService(db, connectivity, [replayer]);

    await service.replayAll();

    expect(replayer.calls, hasLength(1));
  });

  test('backoff thresholds: a row is not due until its schedule slot has elapsed', () async {
    // retryCount 1 -> due after 5s. 4s ago is not due; 6s ago is due.
    await _seedRow(db, entityId: 1, retryCount: 1, lastAttemptAt: DateTime.now().subtract(const Duration(seconds: 4)));
    await _seedRow(db, entityId: 2, retryCount: 1, lastAttemptAt: DateTime.now().subtract(const Duration(seconds: 6)));
    final replayer = FakeOutboxReplayer(db);
    final service = SyncService(db, connectivity, [replayer]);

    await service.replayAll();

    expect(replayer.calls.map((r) => r.entityId), [2]);
  });

  test('a row at the max retry count is held and never selected', () async {
    await _seedRow(db, entityId: 1, retryCount: 6, lastAttemptAt: DateTime.now().subtract(const Duration(days: 1)));
    final replayer = FakeOutboxReplayer(db);
    final service = SyncService(db, connectivity, [replayer]);

    await service.replayAll();

    expect(replayer.calls, isEmpty);
  });

  test('replayAll processes due rows oldest-first', () async {
    await _seedRow(db, entityId: 2, createdAt: DateTime(2026, 1, 2));
    await _seedRow(db, entityId: 1, createdAt: DateTime(2026, 1, 1));
    await _seedRow(db, entityId: 3, createdAt: DateTime(2026, 1, 3));
    final replayer = FakeOutboxReplayer(db);
    final service = SyncService(db, connectivity, [replayer]);

    await service.replayAll();

    expect(replayer.calls.map((r) => r.entityId), [1, 2, 3]);
  });

  test('a failure increments retryCount and stamps lastAttemptAt/lastError, without dropping the row', () async {
    final rowId = await _seedRow(db, entityId: 1);
    final replayer = FakeOutboxReplayer(db)..failuresByRowId[rowId] = const NetworkFailure();
    final service = SyncService(db, connectivity, [replayer]);

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
    final service = SyncService(db, connectivity, [replayer]);

    await service.replayAll();

    expect(replayer.calls, hasLength(2));
    expect(replayer.calls[0].entityId, tempId); // the create, seen before reconciliation
    expect(replayer.calls[1].entityId, realId); // the update, seen AFTER reconciliation patched it
  });

  test('connectivity regained triggers a background replayAll()', () async {
    await _seedRow(db, entityId: 1);
    final replayer = FakeOutboxReplayer(db);
    SyncService(db, connectivity, [replayer]);

    connectivityController.add(true);
    await pumpEventQueue();

    expect(replayer.calls, hasLength(1));
  });

  test('a cold-start check that finds connectivity already up also triggers a replay', () async {
    when(() => connectivity.isConnected()).thenAnswer((_) async => true);
    await _seedRow(db, entityId: 1);
    final replayer = FakeOutboxReplayer(db);
    SyncService(db, connectivity, [replayer]);

    await pumpEventQueue();

    expect(replayer.calls, hasLength(1));
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
      final service = SyncService(db, connectivity, [replayer]);

      final result = await service.replayRow(rowId);

      expect(result, const Right<Failure, Object?>(null));
      expect(replayer.calls, hasLength(1));
    });

    test('no-ops safely when the row no longer exists', () async {
      final replayer = FakeOutboxReplayer(db);
      final service = SyncService(db, connectivity, [replayer]);

      final result = await service.replayRow(12345);

      expect(result, const Right<Failure, Object?>(null));
      expect(replayer.calls, isEmpty);
    });
  });
}
