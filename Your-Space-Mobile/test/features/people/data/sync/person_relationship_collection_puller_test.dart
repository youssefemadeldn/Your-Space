import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/people/data/sync/person_relationship_collection_puller.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_relationship_repository.dart';

class MockPersonRelationshipRepository extends Mock implements PersonRelationshipRepository {}

void main() {
  late MockPersonRelationshipRepository repository;
  late PersonRelationshipCollectionPuller puller;

  setUp(() {
    repository = MockPersonRelationshipRepository();
    GetIt.instance.registerSingleton<PersonRelationshipRepository>(repository);
    puller = PersonRelationshipCollectionPuller();
  });

  tearDown(() => GetIt.instance.reset());

  test('collection is personRelationships', () {
    expect(puller.collection, 'personRelationships');
  });

  test('pull delegates straight to PersonRelationshipRepository.refreshRelationships', () async {
    when(() => repository.refreshRelationships()).thenAnswer((_) async => const Right(unit));

    final result = await puller.pull();

    expect(result, const Right(unit));
    verify(() => repository.refreshRelationships()).called(1);
  });

  test('pull propagates a failure from refreshRelationships unchanged', () async {
    const failure = NetworkFailure();
    when(() => repository.refreshRelationships()).thenAnswer((_) async => const Left(failure));

    final result = await puller.pull();

    expect(result, const Left(failure));
  });
}
