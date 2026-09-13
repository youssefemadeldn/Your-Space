import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/database/app_database.dart';
import 'package:your_space_mobile/core/entities/governorate.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/classification/data/datasources/base_governorate_data_source.dart';
import 'package:your_space_mobile/features/classification/data/datasources/governorate_local_data_source_impl.dart';
import 'package:your_space_mobile/features/classification/data/models/create_governorate_request.dart';
import 'package:your_space_mobile/features/classification/data/models/governorate_response.dart';
import 'package:your_space_mobile/features/classification/data/sync/governorate_outbox_replayer.dart';

class MockBaseGovernorateDataSource extends Mock implements BaseGovernorateDataSource {}

class MockGovernorateLocalDataSourceImpl extends Mock implements GovernorateLocalDataSourceImpl {}

OutboxTableData _row({
  int id = 1,
  int entityId = -1,
  required String operation,
  required String payloadJson,
}) =>
    OutboxTableData(
      id: id,
      entityType: 'governorate',
      entityId: entityId,
      operation: operation,
      payloadJson: payloadJson,
      createdAt: DateTime(2026),
      retryCount: 0,
    );

const _governorateResponse = GovernorateResponse(id: 999, name: 'Custom', isLocked: false);

void main() {
  late MockBaseGovernorateDataSource remote;
  late MockGovernorateLocalDataSourceImpl local;
  late GovernorateOutboxReplayer replayer;

  setUpAll(() {
    registerFallbackValue(const CreateGovernorateRequest(name: ''));
    registerFallbackValue(const Governorate(id: 0, name: ''));
  });

  setUp(() {
    remote = MockBaseGovernorateDataSource();
    local = MockGovernorateLocalDataSourceImpl();
    replayer = GovernorateOutboxReplayer(remote, local);
    when(() => local.reconcileCreatedGovernorate(
          tempId: any(named: 'tempId'),
          realGovernorate: any(named: 'realGovernorate'),
          replayedOutboxRowId: any(named: 'replayedOutboxRowId'),
        )).thenAnswer((_) async {});
  });

  test('entityType is governorate', () {
    expect(replayer.entityType, 'governorate');
  });

  group('create', () {
    test('success decodes the payload, calls remote.createGovernorate, and reconciles the temp id', () async {
      when(() => remote.createGovernorate(any())).thenAnswer((_) async => const Right(_governorateResponse));
      final row = _row(id: 5, entityId: -42, operation: 'create', payloadJson: '{"name":"Custom"}');

      final result = await replayer.replay(row);

      expect(result.isRight(), isTrue);
      final captured =
          verify(() => remote.createGovernorate(captureAny())).captured.single as CreateGovernorateRequest;
      expect(captured.name, 'Custom');
      verify(
        () => local.reconcileCreatedGovernorate(
          tempId: -42,
          realGovernorate: _governorateResponse.toEntity(),
          replayedOutboxRowId: 5,
        ),
      ).called(1);
    });

    test('failure returns Left and never reconciles', () async {
      const failure = NetworkFailure();
      when(() => remote.createGovernorate(any())).thenAnswer((_) async => const Left(failure));
      final row = _row(operation: 'create', payloadJson: '{"name":"Custom"}');

      final result = await replayer.replay(row);

      expect(result, const Left(failure));
      verifyNever(() => local.reconcileCreatedGovernorate(
            tempId: any(named: 'tempId'),
            realGovernorate: any(named: 'realGovernorate'),
            replayedOutboxRowId: any(named: 'replayedOutboxRowId'),
          ));
    });
  });

  test('an unrecognized operation returns Left without throwing', () async {
    final row = _row(operation: 'update', payloadJson: '{}');

    final result = await replayer.replay(row);

    expect(result.isLeft(), isTrue);
    verifyZeroInteractions(remote);
  });
}
