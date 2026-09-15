import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/neighborhood.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_neighborhood_repository.dart';
import 'package:your_space_mobile/features/classification/presentation/cubit/neighborhood_action_cubit/neighborhood_action_cubit.dart';
import 'package:your_space_mobile/features/classification/presentation/cubit/neighborhood_action_cubit/neighborhood_action_state.dart';

class MockNeighborhoodRepository extends Mock implements NeighborhoodRepository {}

void main() {
  late MockNeighborhoodRepository repository;
  late NeighborhoodActionCubit cubit;

  setUp(() {
    repository = MockNeighborhoodRepository();
    cubit = NeighborhoodActionCubit(repository);
  });

  tearDown(() => cubit.close());

  test('createNeighborhood emits [Submitting, SaveSuccess] with the created neighborhood', () async {
    when(() => repository.createNeighborhood(
          cityId: any(named: 'cityId'),
          name: any(named: 'name'),
          nameAr: any(named: 'nameAr'),
        )).thenAnswer((_) async => const Right(Neighborhood(id: 5, cityId: 7, name: 'Zamalek')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const NeighborhoodActionSubmitting(),
        isA<NeighborhoodActionSaveSuccess>().having((s) => s.neighborhood.name, 'neighborhood.name', 'Zamalek'),
      ]),
    );

    unawaited(cubit.createNeighborhood(cityId: 7, name: 'Zamalek'));
    await expectation;
  });

  test('updateNeighborhood emits [Submitting, SaveSuccess] with the renamed neighborhood', () async {
    when(() => repository.updateNeighborhood(
          cityId: any(named: 'cityId'),
          id: any(named: 'id'),
          name: any(named: 'name'),
          nameAr: any(named: 'nameAr'),
        )).thenAnswer((_) async => const Right(Neighborhood(id: 1, cityId: 7, name: 'Zamalek (Updated)')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const NeighborhoodActionSubmitting(),
        isA<NeighborhoodActionSaveSuccess>()
            .having((s) => s.neighborhood.name, 'neighborhood.name', 'Zamalek (Updated)'),
      ]),
    );

    unawaited(cubit.updateNeighborhood(cityId: 7, id: 1, name: 'Zamalek (Updated)'));
    await expectation;
  });

  test('deleteNeighborhood emits [Submitting, DeleteSuccess]', () async {
    when(() => repository.deleteNeighborhood(cityId: any(named: 'cityId'), id: any(named: 'id')))
        .thenAnswer((_) async => const Right(unit));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const NeighborhoodActionSubmitting(), isA<NeighborhoodActionDeleteSuccess>()]),
    );

    unawaited(cubit.deleteNeighborhood(cityId: 7, id: 1));
    await expectation;
  });

  test('createNeighborhood emits [Submitting, Error] on failure', () async {
    when(() => repository.createNeighborhood(
          cityId: any(named: 'cityId'),
          name: any(named: 'name'),
          nameAr: any(named: 'nameAr'),
        )).thenAnswer((_) async => const Left(ServerFailure(statusCode: 422, message: 'Name is required')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const NeighborhoodActionSubmitting(), isA<NeighborhoodActionError>()]),
    );

    unawaited(cubit.createNeighborhood(cityId: 7, name: ''));
    await expectation;
  });
}
