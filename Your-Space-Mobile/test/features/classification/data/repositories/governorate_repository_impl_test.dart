import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/governorate.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/paginated_response.dart';
import 'package:your_space_mobile/features/classification/data/datasources/base_governorate_data_source.dart';
import 'package:your_space_mobile/features/classification/data/datasources/governorate_local_data_source_impl.dart';
import 'package:your_space_mobile/features/classification/data/models/create_governorate_request.dart';
import 'package:your_space_mobile/features/classification/data/models/governorate_response.dart';
import 'package:your_space_mobile/features/classification/data/repositories/governorate_repository_impl.dart';

class MockBaseGovernorateDataSource extends Mock implements BaseGovernorateDataSource {}

class MockGovernorateLocalDataSourceImpl extends Mock implements GovernorateLocalDataSourceImpl {}

void main() {
  late MockBaseGovernorateDataSource remote;
  late MockGovernorateLocalDataSourceImpl local;
  late GovernorateRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const CreateGovernorateRequest(name: ''));
    registerFallbackValue(const Governorate(id: 0, name: ''));
  });

  setUp(() {
    remote = MockBaseGovernorateDataSource();
    local = MockGovernorateLocalDataSourceImpl();
    repository = GovernorateRepositoryImpl(remote, local);
    when(() => local.saveGovernorate(any())).thenAnswer((_) async {});
  });

  test('getGovernorates maps a paginated response to a PaginatedResult of entities', () async {
    when(() => remote.getGovernorates(search: any(named: 'search'), pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResponse(
        items: [
          GovernorateResponse(id: 1, name: 'Cairo', isLocked: true),
          GovernorateResponse(id: 2, name: 'Giza', isLocked: true),
        ],
        pageIndex: 1,
        totalPages: 1,
        totalItems: 2,
      )),
    );

    final result = await repository.getGovernorates(pageIndex: 1, pageSize: 20);

    expect(result.isRight(), isTrue);
    final page = result.getOrElse(() => throw StateError('expected Right'));
    expect(page.items.map((g) => g.name), ['Cairo', 'Giza']);
    expect(page.totalItems, 2);
  });

  test('getGovernorates propagates a failure unchanged', () async {
    const failure = NetworkFailure();
    when(() => remote.getGovernorates(search: any(named: 'search'), pageIndex: 1, pageSize: 20))
        .thenAnswer((_) async => const Left(failure));

    final result = await repository.getGovernorates(pageIndex: 1, pageSize: 20);

    expect(result, const Left(failure));
  });

  test('createGovernorate maps the response to an entity and saves it locally', () async {
    when(() => remote.createGovernorate(any()))
        .thenAnswer((_) async => const Right(GovernorateResponse(id: 5, name: 'Custom', isLocked: false)));

    final result = await repository.createGovernorate(name: 'Custom');

    expect(result, const Right(Governorate(id: 5, name: 'Custom')));
    verify(() => local.saveGovernorate(const Governorate(id: 5, name: 'Custom'))).called(1);
  });

  test('createGovernorate propagates a failure without touching local storage', () async {
    const failure = NetworkFailure();
    when(() => remote.createGovernorate(any())).thenAnswer((_) async => const Left(failure));

    final result = await repository.createGovernorate(name: 'Custom');

    expect(result, const Left(failure));
    verifyNever(() => local.saveGovernorate(any()));
  });

  test('watchGovernorates delegates straight to the local data source', () {
    when(() => local.watchGovernorates(search: 'cai', limit: 20)).thenAnswer(
      (_) => Stream.value(const [Governorate(id: 1, name: 'Cairo', isLocked: true)]),
    );

    final stream = repository.watchGovernorates(search: 'cai', limit: 20);

    expect(stream, emits(const [Governorate(id: 1, name: 'Cairo', isLocked: true)]));
  });

  test('countGovernorates delegates straight to the local data source', () async {
    when(() => local.countGovernorates(search: null)).thenAnswer((_) async => 27);

    final count = await repository.countGovernorates();

    expect(count, 27);
  });
}
