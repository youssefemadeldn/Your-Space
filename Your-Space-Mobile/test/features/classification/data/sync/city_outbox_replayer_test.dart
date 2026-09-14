import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/city.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/classification/data/datasources/base_city_data_source.dart';
import 'package:your_space_mobile/features/classification/data/datasources/city_local_data_source_impl.dart';
import 'package:your_space_mobile/features/classification/data/models/city_response.dart';
import 'package:your_space_mobile/features/classification/data/models/create_city_request.dart';
import 'package:your_space_mobile/features/classification/data/models/update_city_request.dart';
import 'package:your_space_mobile/features/classification/data/sync/city_outbox_replayer.dart';

class MockBaseCityDataSource extends Mock implements BaseCityDataSource {}

class MockCityLocalDataSourceImpl extends Mock implements CityLocalDataSourceImpl {}

OutboxTableData _row({
  int id = 1,
  int entityId = -1,
  required String operation,
  required String payloadJson,
}) =>
    OutboxTableData(
      id: id,
      entityType: 'city',
      entityId: entityId,
      operation: operation,
      payloadJson: payloadJson,
      createdAt: DateTime(2026),
      retryCount: 0,
    );

const _cityResponse = CityResponse(id: 999, governorateId: 7, name: 'Maadi');

void main() {
  late MockBaseCityDataSource remote;
  late MockCityLocalDataSourceImpl local;
  late CityOutboxReplayer replayer;

  setUpAll(() {
    registerFallbackValue(const CreateCityRequest(name: ''));
    registerFallbackValue(const UpdateCityRequest(name: ''));
    registerFallbackValue(const City(id: 0, governorateId: 0, name: ''));
  });

  setUp(() {
    remote = MockBaseCityDataSource();
    local = MockCityLocalDataSourceImpl();
    replayer = CityOutboxReplayer(remote, local);
    when(() => local.reconcileCreatedCity(
          tempId: any(named: 'tempId'),
          realCity: any(named: 'realCity'),
          replayedOutboxRowId: any(named: 'replayedOutboxRowId'),
        )).thenAnswer((_) async {});
    when(() => local.confirmSyncedCity(any(), replayedOutboxRowId: any(named: 'replayedOutboxRowId')))
        .thenAnswer((_) async {});
    when(() => local.confirmDeletedCity(any(), replayedOutboxRowId: any(named: 'replayedOutboxRowId')))
        .thenAnswer((_) async {});
  });

  test('entityType is city', () {
    expect(replayer.entityType, 'city');
  });

  group('create', () {
    test('success decodes the payload, calls remote.createCity with the parent id, and reconciles the temp id',
        () async {
      when(() => remote.createCity(7, any())).thenAnswer((_) async => const Right(_cityResponse));
      final row = _row(
        id: 5,
        entityId: -42,
        operation: 'create',
        payloadJson: '{"governorateId":7,"name":"Maadi"}',
      );

      final result = await replayer.replay(row);

      expect(result.isRight(), isTrue);
      final captured = verify(() => remote.createCity(7, captureAny())).captured.single as CreateCityRequest;
      expect(captured.name, 'Maadi');
      verify(
        () => local.reconcileCreatedCity(tempId: -42, realCity: _cityResponse.toEntity(), replayedOutboxRowId: 5),
      ).called(1);
    });

    test('failure returns Left and never reconciles', () async {
      const failure = NetworkFailure();
      when(() => remote.createCity(7, any())).thenAnswer((_) async => const Left(failure));
      final row = _row(operation: 'create', payloadJson: '{"governorateId":7,"name":"Maadi"}');

      final result = await replayer.replay(row);

      expect(result, const Left(failure));
      verifyNever(() => local.reconcileCreatedCity(
            tempId: any(named: 'tempId'),
            realCity: any(named: 'realCity'),
            replayedOutboxRowId: any(named: 'replayedOutboxRowId'),
          ));
    });
  });

  group('update', () {
    test('success decodes the payload, calls remote.updateCity with the entity id, and confirms the sync', () async {
      when(() => remote.updateCity(7, 999, any())).thenAnswer((_) async => const Right(_cityResponse));
      final row = _row(
        id: 7,
        entityId: 999,
        operation: 'update',
        payloadJson: '{"governorateId":7,"name":"Maadi"}',
      );

      final result = await replayer.replay(row);

      expect(result.isRight(), isTrue);
      final captured = verify(() => remote.updateCity(7, 999, captureAny())).captured.single as UpdateCityRequest;
      expect(captured.name, 'Maadi');
      verify(() => local.confirmSyncedCity(_cityResponse.toEntity(), replayedOutboxRowId: 7)).called(1);
    });

    test('failure returns Left and never confirms', () async {
      const failure = ServerFailure(statusCode: 500, message: 'boom');
      when(() => remote.updateCity(7, 999, any())).thenAnswer((_) async => const Left(failure));
      final row = _row(entityId: 999, operation: 'update', payloadJson: '{"governorateId":7,"name":"Maadi"}');

      final result = await replayer.replay(row);

      expect(result, const Left(failure));
      verifyNever(() => local.confirmSyncedCity(any(), replayedOutboxRowId: any(named: 'replayedOutboxRowId')));
    });
  });

  group('delete', () {
    test('success calls remote.deleteCity with the parent id and hard-removes the local row', () async {
      when(() => remote.deleteCity(7, 999)).thenAnswer((_) async => const Right(unit));
      final row = _row(id: 11, entityId: 999, operation: 'delete', payloadJson: '{"governorateId":7}');

      final result = await replayer.replay(row);

      expect(result.isRight(), isTrue);
      verify(() => remote.deleteCity(7, 999)).called(1);
      verify(() => local.confirmDeletedCity(999, replayedOutboxRowId: 11)).called(1);
    });

    test('failure returns Left and never confirms', () async {
      const failure = NetworkFailure();
      when(() => remote.deleteCity(7, 999)).thenAnswer((_) async => const Left(failure));
      final row = _row(entityId: 999, operation: 'delete', payloadJson: '{"governorateId":7}');

      final result = await replayer.replay(row);

      expect(result, const Left(failure));
      verifyNever(() => local.confirmDeletedCity(any(), replayedOutboxRowId: any(named: 'replayedOutboxRowId')));
    });
  });

  test('an unrecognized operation returns Left without throwing', () async {
    final row = _row(operation: 'unknown', payloadJson: '{"governorateId":7}');

    final result = await replayer.replay(row);

    expect(result.isLeft(), isTrue);
    verifyZeroInteractions(remote);
  });
}
