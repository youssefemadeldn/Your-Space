import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/people/data/sync/person_collection_puller.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';

class MockPersonRepository extends Mock implements PersonRepository {}

void main() {
  late MockPersonRepository repository;
  late PersonCollectionPuller puller;

  setUp(() {
    repository = MockPersonRepository();
    puller = PersonCollectionPuller(repository);
  });

  test('collection is persons', () {
    expect(puller.collection, 'persons');
  });

  test('pull delegates straight to PersonRepository.refreshPersons', () async {
    when(() => repository.refreshPersons()).thenAnswer((_) async => const Right(unit));

    final result = await puller.pull();

    expect(result, const Right(unit));
    verify(() => repository.refreshPersons()).called(1);
  });

  test('pull propagates a failure from refreshPersons unchanged', () async {
    const failure = NetworkFailure();
    when(() => repository.refreshPersons()).thenAnswer((_) async => const Left(failure));

    final result = await puller.pull();

    expect(result, const Left(failure));
  });
}
