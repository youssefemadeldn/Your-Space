import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/classification/data/sync/subgroup_collection_puller.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_subgroup_repository.dart';

class MockSubGroupRepository extends Mock implements SubGroupRepository {}

void main() {
  late MockSubGroupRepository repository;
  late SubGroupCollectionPuller puller;

  setUp(() {
    repository = MockSubGroupRepository();
    GetIt.instance.registerSingleton<SubGroupRepository>(repository);
    puller = SubGroupCollectionPuller();
  });

  tearDown(() => GetIt.instance.reset());

  test('collection is subgroups', () {
    expect(puller.collection, 'subgroups');
  });

  test('pull delegates straight to SubGroupRepository.refreshSubGroups', () async {
    when(() => repository.refreshSubGroups()).thenAnswer((_) async => const Right(unit));

    final result = await puller.pull();

    expect(result, const Right(unit));
    verify(() => repository.refreshSubGroups()).called(1);
  });

  test('pull propagates a failure from refreshSubGroups unchanged', () async {
    const failure = NetworkFailure();
    when(() => repository.refreshSubGroups()).thenAnswer((_) async => const Left(failure));

    final result = await puller.pull();

    expect(result, const Left(failure));
  });
}
