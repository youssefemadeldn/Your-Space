import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/classification/data/sync/governorate_collection_puller.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_governorate_repository.dart';

class MockGovernorateRepository extends Mock implements GovernorateRepository {}

void main() {
  late MockGovernorateRepository repository;
  late GovernorateCollectionPuller puller;

  setUp(() {
    repository = MockGovernorateRepository();
    puller = GovernorateCollectionPuller(repository);
  });

  test('collection is governorates', () {
    expect(puller.collection, 'governorates');
  });

  test('pull delegates straight to GovernorateRepository.refreshGovernorates', () async {
    when(() => repository.refreshGovernorates()).thenAnswer((_) async => const Right(unit));

    final result = await puller.pull();

    expect(result, const Right(unit));
    verify(() => repository.refreshGovernorates()).called(1);
  });

  test('pull propagates a failure from refreshGovernorates unchanged', () async {
    const failure = NetworkFailure();
    when(() => repository.refreshGovernorates()).thenAnswer((_) async => const Left(failure));

    final result = await puller.pull();

    expect(result, const Left(failure));
  });
}
