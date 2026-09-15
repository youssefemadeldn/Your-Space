import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/neighborhood.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/classification/data/datasources/base_neighborhood_data_source.dart';
import 'package:your_space_mobile/features/classification/data/datasources/neighborhood_local_data_source_impl.dart';
import 'package:your_space_mobile/features/classification/data/models/create_neighborhood_request.dart';
import 'package:your_space_mobile/features/classification/data/models/neighborhood_response.dart';
import 'package:your_space_mobile/features/classification/data/models/update_neighborhood_request.dart';
import 'package:your_space_mobile/features/classification/data/sync/neighborhood_outbox_replayer.dart';

class MockBaseNeighborhoodDataSource extends Mock implements BaseNeighborhoodDataSource {}

class MockNeighborhoodLocalDataSourceImpl extends Mock implements NeighborhoodLocalDataSourceImpl {}

OutboxTableData _row({
  int id = 1,
  int entityId = -1,
  required String operation,
  required String payloadJson,
}) =>
    OutboxTableData(
      id: id,
      entityType: 'neighborhood',
      entityId: entityId,
      operation: operation,
      payloadJson: payloadJson,
      createdAt: DateTime(2026),
      retryCount: 0,
    );

const _neighborhoodResponse = NeighborhoodResponse(id: 999, cityId: 7, name: 'Zamalek');

void main() {
  late MockBaseNeighborhoodDataSource remote;
  late MockNeighborhoodLocalDataSourceImpl local;
  late NeighborhoodOutboxReplayer replayer;

  setUpAll(() {
    registerFallbackValue(const CreateNeighborhoodRequest(name: ''));
    registerFallbackValue(const UpdateNeighborhoodRequest(name: ''));
    registerFallbackValue(const Neighborhood(id: 0, cityId: 0, name: ''));
  });

  setUp(() {
    remote = MockBaseNeighborhoodDataSource();
    local = MockNeighborhoodLocalDataSourceImpl();
    replayer = NeighborhoodOutboxReplayer(remote, local);
    when(() => local.reconcileCreatedNeighborhood(
          tempId: any(named: 'tempId'),
          realNeighborhood: any(named: 'realNeighborhood'),
          replayedOutboxRowId: any(named: 'replayedOutboxRowId'),
        )).thenAnswer((_) async {});
    when(() => local.confirmSyncedNeighborhood(any(), replayedOutboxRowId: any(named: 'replayedOutboxRowId')))
        .thenAnswer((_) async {});
    when(() => local.confirmDeletedNeighborhood(any(), replayedOutboxRowId: any(named: 'replayedOutboxRowId')))
        .thenAnswer((_) async {});
  });

  test('entityType is neighborhood', () {
    expect(replayer.entityType, 'neighborhood');
  });

  group('create', () {
    test(
      'success decodes the payload, calls remote.createNeighborhood with the parent id, and reconciles the temp id',
      () async {
        when(() => remote.createNeighborhood(7, any())).thenAnswer((_) async => const Right(_neighborhoodResponse));
        final row = _row(
          id: 5,
          entityId: -42,
          operation: 'create',
          payloadJson: '{"cityId":7,"name":"Zamalek"}',
        );

        final result = await replayer.replay(row);

        expect(result.isRight(), isTrue);
        final captured =
            verify(() => remote.createNeighborhood(7, captureAny())).captured.single as CreateNeighborhoodRequest;
        expect(captured.name, 'Zamalek');
        verify(
          () => local.reconcileCreatedNeighborhood(
            tempId: -42,
            realNeighborhood: _neighborhoodResponse.toEntity(),
            replayedOutboxRowId: 5,
          ),
        ).called(1);
      },
    );

    test('failure returns Left and never reconciles', () async {
      const failure = NetworkFailure();
      when(() => remote.createNeighborhood(7, any())).thenAnswer((_) async => const Left(failure));
      final row = _row(operation: 'create', payloadJson: '{"cityId":7,"name":"Zamalek"}');

      final result = await replayer.replay(row);

      expect(result, const Left(failure));
      verifyNever(() => local.reconcileCreatedNeighborhood(
            tempId: any(named: 'tempId'),
            realNeighborhood: any(named: 'realNeighborhood'),
            replayedOutboxRowId: any(named: 'replayedOutboxRowId'),
          ));
    });
  });

  group('update', () {
    test(
      'success decodes the payload, calls remote.updateNeighborhood with the entity id, and confirms the sync',
      () async {
        when(() => remote.updateNeighborhood(7, 999, any()))
            .thenAnswer((_) async => const Right(_neighborhoodResponse));
        final row = _row(
          id: 7,
          entityId: 999,
          operation: 'update',
          payloadJson: '{"cityId":7,"name":"Zamalek"}',
        );

        final result = await replayer.replay(row);

        expect(result.isRight(), isTrue);
        final captured = verify(() => remote.updateNeighborhood(7, 999, captureAny())).captured.single
            as UpdateNeighborhoodRequest;
        expect(captured.name, 'Zamalek');
        verify(() => local.confirmSyncedNeighborhood(_neighborhoodResponse.toEntity(), replayedOutboxRowId: 7))
            .called(1);
      },
    );

    test('failure returns Left and never confirms', () async {
      const failure = ServerFailure(statusCode: 500, message: 'boom');
      when(() => remote.updateNeighborhood(7, 999, any())).thenAnswer((_) async => const Left(failure));
      final row = _row(entityId: 999, operation: 'update', payloadJson: '{"cityId":7,"name":"Zamalek"}');

      final result = await replayer.replay(row);

      expect(result, const Left(failure));
      verifyNever(
        () => local.confirmSyncedNeighborhood(any(), replayedOutboxRowId: any(named: 'replayedOutboxRowId')),
      );
    });
  });

  group('delete', () {
    test('success calls remote.deleteNeighborhood with the parent id and hard-removes the local row', () async {
      when(() => remote.deleteNeighborhood(7, 999)).thenAnswer((_) async => const Right(unit));
      final row = _row(id: 11, entityId: 999, operation: 'delete', payloadJson: '{"cityId":7}');

      final result = await replayer.replay(row);

      expect(result.isRight(), isTrue);
      verify(() => remote.deleteNeighborhood(7, 999)).called(1);
      verify(() => local.confirmDeletedNeighborhood(999, replayedOutboxRowId: 11)).called(1);
    });

    test('failure returns Left and never confirms', () async {
      const failure = NetworkFailure();
      when(() => remote.deleteNeighborhood(7, 999)).thenAnswer((_) async => const Left(failure));
      final row = _row(entityId: 999, operation: 'delete', payloadJson: '{"cityId":7}');

      final result = await replayer.replay(row);

      expect(result, const Left(failure));
      verifyNever(
        () => local.confirmDeletedNeighborhood(any(), replayedOutboxRowId: any(named: 'replayedOutboxRowId')),
      );
    });
  });

  test('an unrecognized operation returns Left without throwing', () async {
    final row = _row(operation: 'unknown', payloadJson: '{"cityId":7}');

    final result = await replayer.replay(row);

    expect(result.isLeft(), isTrue);
    verifyZeroInteractions(remote);
  });
}
