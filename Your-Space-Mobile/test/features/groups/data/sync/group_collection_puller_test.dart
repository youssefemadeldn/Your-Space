import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/groups/data/sync/group_collection_puller.dart';
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockGroupRepository repository;
  late GroupCollectionPuller puller;

  setUp(() {
    repository = MockGroupRepository();
    puller = GroupCollectionPuller(repository);
  });

  test('collection is groups', () {
    expect(puller.collection, 'groups');
  });

  test('pull delegates straight to GroupRepository.refreshGroups', () async {
    when(() => repository.refreshGroups()).thenAnswer((_) async => const Right(unit));

    final result = await puller.pull();

    expect(result, const Right(unit));
    verify(() => repository.refreshGroups()).called(1);
  });

  test('pull propagates a failure from refreshGroups unchanged', () async {
    const failure = NetworkFailure();
    when(() => repository.refreshGroups()).thenAnswer((_) async => const Left(failure));

    final result = await puller.pull();

    expect(result, const Left(failure));
  });
}
