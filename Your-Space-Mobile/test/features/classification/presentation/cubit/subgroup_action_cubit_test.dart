import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/subgroup.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_subgroup_repository.dart';
import 'package:your_space_mobile/features/classification/presentation/cubit/subgroup_action_cubit/subgroup_action_cubit.dart';
import 'package:your_space_mobile/features/classification/presentation/cubit/subgroup_action_cubit/subgroup_action_state.dart';

class MockSubGroupRepository extends Mock implements SubGroupRepository {}

void main() {
  late MockSubGroupRepository repository;
  late SubGroupActionCubit cubit;

  setUp(() {
    repository = MockSubGroupRepository();
    cubit = SubGroupActionCubit(repository);
  });

  tearDown(() => cubit.close());

  test('createSubGroup emits [Submitting, SaveSuccess] with the created subgroup', () async {
    when(() => repository.createSubGroup(
          groupId: any(named: 'groupId'),
          name: any(named: 'name'),
          nameAr: any(named: 'nameAr'),
        )).thenAnswer((_) async => const Right(SubGroup(id: 5, groupId: 7, name: 'Book club')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const SubGroupActionSubmitting(),
        isA<SubGroupActionSaveSuccess>().having((s) => s.subGroup.name, 'subGroup.name', 'Book club'),
      ]),
    );

    unawaited(cubit.createSubGroup(groupId: 7, name: 'Book club'));
    await expectation;
  });

  test('updateSubGroup emits [Submitting, SaveSuccess] with the renamed subgroup', () async {
    when(() => repository.updateSubGroup(
          groupId: any(named: 'groupId'),
          id: any(named: 'id'),
          name: any(named: 'name'),
          nameAr: any(named: 'nameAr'),
        )).thenAnswer((_) async => const Right(SubGroup(id: 1, groupId: 7, name: 'Immediate Family (Updated)')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const SubGroupActionSubmitting(),
        isA<SubGroupActionSaveSuccess>().having((s) => s.subGroup.name, 'subGroup.name', 'Immediate Family (Updated)'),
      ]),
    );

    unawaited(cubit.updateSubGroup(groupId: 7, id: 1, name: 'Immediate Family (Updated)'));
    await expectation;
  });

  test('deleteSubGroup emits [Submitting, DeleteSuccess]', () async {
    when(() => repository.deleteSubGroup(groupId: any(named: 'groupId'), id: any(named: 'id')))
        .thenAnswer((_) async => const Right(unit));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const SubGroupActionSubmitting(), isA<SubGroupActionDeleteSuccess>()]),
    );

    unawaited(cubit.deleteSubGroup(groupId: 7, id: 1));
    await expectation;
  });

  test('createSubGroup emits [Submitting, Error] on failure', () async {
    when(() => repository.createSubGroup(
          groupId: any(named: 'groupId'),
          name: any(named: 'name'),
          nameAr: any(named: 'nameAr'),
        )).thenAnswer((_) async => const Left(ServerFailure(statusCode: 422, message: 'Name is required')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const SubGroupActionSubmitting(), isA<SubGroupActionError>()]),
    );

    unawaited(cubit.createSubGroup(groupId: 7, name: ''));
    await expectation;
  });
}
