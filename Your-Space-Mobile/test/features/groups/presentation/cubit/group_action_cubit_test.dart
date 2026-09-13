import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';
import 'package:your_space_mobile/features/groups/presentation/cubit/group_action_cubit/group_action_cubit.dart';
import 'package:your_space_mobile/features/groups/presentation/cubit/group_action_cubit/group_action_state.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockGroupRepository repository;
  late GroupActionCubit cubit;

  setUp(() {
    repository = MockGroupRepository();
    cubit = GroupActionCubit(repository);
  });

  tearDown(() => cubit.close());

  test('createGroup emits [Submitting, Success] with the created group', () async {
    when(() => repository.createGroup(name: any(named: 'name'), nameAr: any(named: 'nameAr')))
        .thenAnswer((_) async => const Right(Group(id: 5, name: 'Book club')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const GroupActionSubmitting(),
        isA<GroupActionSuccess>().having((s) => s.group.name, 'group.name', 'Book club'),
      ]),
    );

    unawaited(cubit.createGroup(name: 'Book club'));
    await expectation;
  });

  test('updateGroup emits [Submitting, Success] with the renamed group', () async {
    when(() => repository.updateGroup(
          id: any(named: 'id'),
          name: any(named: 'name'),
          nameAr: any(named: 'nameAr'),
        )).thenAnswer((_) async => const Right(Group(id: 1, name: 'The Family')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const GroupActionSubmitting(),
        isA<GroupActionSuccess>().having((s) => s.group.name, 'group.name', 'The Family'),
      ]),
    );

    unawaited(cubit.updateGroup(id: 1, name: 'The Family'));
    await expectation;
  });

  test('createGroup emits [Submitting, Error] on failure', () async {
    when(() => repository.createGroup(name: any(named: 'name'), nameAr: any(named: 'nameAr')))
        .thenAnswer((_) async => const Left(ServerFailure(statusCode: 422, message: 'Name is required')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const GroupActionSubmitting(), isA<GroupActionError>()]),
    );

    unawaited(cubit.createGroup(name: ''));
    await expectation;
  });
}
