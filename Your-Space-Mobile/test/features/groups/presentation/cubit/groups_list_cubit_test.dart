import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';
import 'package:your_space_mobile/features/groups/presentation/cubit/groups_list_cubit/groups_list_cubit.dart';
import 'package:your_space_mobile/features/groups/presentation/cubit/groups_list_cubit/groups_list_state.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockGroupRepository repository;
  late GroupsListCubit cubit;

  const group1 = Group(id: 1, name: 'Family');
  const group2 = Group(id: 2, name: 'Close friends');

  setUp(() {
    repository = MockGroupRepository();
    cubit = GroupsListCubit(repository);
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] with the first page on load', () async {
    when(() => repository.getGroups(pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [group1, group2], pageIndex: 1, totalPages: 1, totalItems: 2)),
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const GroupsListLoading(),
        isA<GroupsListSuccess>()
            .having((s) => s.groups.length, 'groups.length', 2)
            .having((s) => s.hasNextPage, 'hasNextPage', false),
      ]),
    );

    unawaited(cubit.load());
    await expectation;
  });

  test('emits [Loading, Error] on failure', () async {
    when(() => repository.getGroups(pageIndex: 1, pageSize: 20))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const GroupsListLoading(), isA<GroupsListError>()]),
    );

    unawaited(cubit.load());
    await expectation;
  });

  test('search debounces then filters the list without a Loading flash', () async {
    when(() => repository.getGroups(pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [group1, group2], pageIndex: 1, totalPages: 1, totalItems: 2)),
    );
    await cubit.load();

    when(() => repository.getGroups(search: 'fam', pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [group1], pageIndex: 1, totalPages: 1, totalItems: 1)),
    );

    cubit.search('fam');
    await Future.delayed(const Duration(milliseconds: 500));

    expect(cubit.state, isA<GroupsListSuccess>().having((s) => s.groups, 'groups', [group1]));
  });

  test('search on an un-loaded cubit is a no-op', () async {
    cubit.search('fam');
    await Future.delayed(const Duration(milliseconds: 500));
    expect(cubit.state, isA<GroupsListInitial>());
    verifyNever(() => repository.getGroups(
          search: any(named: 'search'),
          pageIndex: any(named: 'pageIndex'),
          pageSize: any(named: 'pageSize'),
        ));
  });

  test('loadMore appends the next page and advances pageIndex', () async {
    when(() => repository.getGroups(pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [group1], pageIndex: 1, totalPages: 2, totalItems: 2)),
    );
    await cubit.load();

    when(() => repository.getGroups(search: null, pageIndex: 2, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [group2], pageIndex: 2, totalPages: 2, totalItems: 2)),
    );

    await cubit.loadMore();

    final state = cubit.state as GroupsListSuccess;
    expect(state.groups, [group1, group2]);
    expect(state.pageIndex, 2);
    expect(state.hasNextPage, isFalse);
  });

  test('loadMore is a no-op when hasNextPage is already false', () async {
    when(() => repository.getGroups(pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [group1], pageIndex: 1, totalPages: 1, totalItems: 1)),
    );
    await cubit.load();

    await cubit.loadMore();

    verifyNever(() => repository.getGroups(
          search: any(named: 'search'),
          pageIndex: 2,
          pageSize: any(named: 'pageSize'),
        ));
  });

  test('loadMore ignores a second concurrent call while the first is in flight', () async {
    when(() => repository.getGroups(pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [group1], pageIndex: 1, totalPages: 2, totalItems: 2)),
    );
    await cubit.load();

    final completer = Completer<Either<Failure, PaginatedResult<Group>>>();
    when(() => repository.getGroups(search: null, pageIndex: 2, pageSize: 20))
        .thenAnswer((_) => completer.future);

    final first = cubit.loadMore();
    final second = cubit.loadMore();
    completer.complete(
      const Right(PaginatedResult(items: [group2], pageIndex: 2, totalPages: 2, totalItems: 2)),
    );
    await first;
    await second;

    verify(() => repository.getGroups(search: null, pageIndex: 2, pageSize: 20)).called(1);
  });
}
