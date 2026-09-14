import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/city.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_city_repository.dart';
import 'package:your_space_mobile/features/classification/presentation/cubit/city_action_cubit/city_action_cubit.dart';
import 'package:your_space_mobile/features/classification/presentation/cubit/city_action_cubit/city_action_state.dart';

class MockCityRepository extends Mock implements CityRepository {}

void main() {
  late MockCityRepository repository;
  late CityActionCubit cubit;

  setUp(() {
    repository = MockCityRepository();
    cubit = CityActionCubit(repository);
  });

  tearDown(() => cubit.close());

  test('createCity emits [Submitting, SaveSuccess] with the created city', () async {
    when(() => repository.createCity(
          governorateId: any(named: 'governorateId'),
          name: any(named: 'name'),
          nameAr: any(named: 'nameAr'),
        )).thenAnswer((_) async => const Right(City(id: 5, governorateId: 7, name: 'Book club')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const CityActionSubmitting(),
        isA<CityActionSaveSuccess>().having((s) => s.city.name, 'city.name', 'Book club'),
      ]),
    );

    unawaited(cubit.createCity(governorateId: 7, name: 'Book club'));
    await expectation;
  });

  test('updateCity emits [Submitting, SaveSuccess] with the renamed city', () async {
    when(() => repository.updateCity(
          governorateId: any(named: 'governorateId'),
          id: any(named: 'id'),
          name: any(named: 'name'),
          nameAr: any(named: 'nameAr'),
        )).thenAnswer((_) async => const Right(City(id: 1, governorateId: 7, name: 'Maadi (Updated)')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const CityActionSubmitting(),
        isA<CityActionSaveSuccess>().having((s) => s.city.name, 'city.name', 'Maadi (Updated)'),
      ]),
    );

    unawaited(cubit.updateCity(governorateId: 7, id: 1, name: 'Maadi (Updated)'));
    await expectation;
  });

  test('deleteCity emits [Submitting, DeleteSuccess]', () async {
    when(() => repository.deleteCity(governorateId: any(named: 'governorateId'), id: any(named: 'id')))
        .thenAnswer((_) async => const Right(unit));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const CityActionSubmitting(), isA<CityActionDeleteSuccess>()]),
    );

    unawaited(cubit.deleteCity(governorateId: 7, id: 1));
    await expectation;
  });

  test('createCity emits [Submitting, Error] on failure', () async {
    when(() => repository.createCity(
          governorateId: any(named: 'governorateId'),
          name: any(named: 'name'),
          nameAr: any(named: 'nameAr'),
        )).thenAnswer((_) async => const Left(ServerFailure(statusCode: 422, message: 'Name is required')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const CityActionSubmitting(), isA<CityActionError>()]),
    );

    unawaited(cubit.createCity(governorateId: 7, name: ''));
    await expectation;
  });
}
