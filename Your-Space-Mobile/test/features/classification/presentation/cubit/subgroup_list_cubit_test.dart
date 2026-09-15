import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/entities/subgroup.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_subgroup_repository.dart';
import 'package:your_space_mobile/features/classification/presentation/cubit/subgroup_list_cubit/subgroup_list_cubit.dart';
import 'package:your_space_mobile/features/classification/presentation/cubit/subgroup_list_cubit/subgroup_list_state.dart';

class MockSubGroupRepository extends Mock implements SubGroupRepository {}

void main() {
  late MockSubGroupRepository repository;
  late SubGroupListCubit cubit;

  const subGroup1 = SubGroup(id: 1, groupId: 7, name: 'Immediate Family');
  const subGroup2 = SubGroup(id: 2, groupId: 7, name: 'Extended Family');

  PaginatedResult<SubGroup> page(List<SubGroup> items) =>
      PaginatedResult(items: items, pageIndex: 1, totalPages: 1, totalItems: items.length);

  /// Stubs a `watchSubGroups`/`countSubGroups` pair for a given search/limit.
  void stubSubGroups({
    int groupId = 7,
    String? search,
    required int limit,
    required List<SubGroup> subGroups,
    required int total,
  }) {
    when(() => repository.watchSubGroups(groupId: groupId, search: search, limit: limit))
        .thenAnswer((_) => Stream.value(subGroups));
    when(() => repository.countSubGroups(groupId: groupId, search: search)).thenAnswer((_) async => total);
  }

  /// The one-shot `getSubGroups` call `SubGroupListCubit` uses purely to
  /// read `personCount` (design doc §8) — defaults to an empty page
  /// (counts default to 0) unless a test stubs otherwise.
  void stubCounts({int groupId = 7, List<SubGroup> withCounts = const []}) {
    when(() => repository.getSubGroups(groupId: groupId, pageIndex: 1, pageSize: 200))
        .thenAnswer((_) async => Right(page(withCounts)));
  }

  setUp(() {
    repository = MockSubGroupRepository();
    cubit = SubGroupListCubit(repository);
    stubCounts();
  });

  tearDown(() {
    cubit.close();
  });

  test('emits [Loading, Success] with the first window on load', () async {
    stubSubGroups(limit: 20, subGroups: const [subGroup1, subGroup2], total: 2);

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const SubGroupListLoading(),
        isA<SubGroupListSuccess>()
            .having((s) => s.subGroups.length, 'subGroups.length', 2)
            .having((s) => s.hasNextPage, 'hasNextPage', false),
      ]),
    );

    await cubit.load(7);
    await expectation;
  });

  test('merges the one-shot personCount onto each locally-cached row', () async {
    stubSubGroups(limit: 20, subGroups: const [subGroup1, subGroup2], total: 2);
    stubCounts(withCounts: const [
      SubGroup(id: 1, groupId: 7, name: 'Immediate Family', personCount: 3),
      SubGroup(id: 2, groupId: 7, name: 'Extended Family', personCount: 5),
    ]);

    await cubit.load(7);

    final state = cubit.state as SubGroupListSuccess;
    expect(state.subGroups.singleWhere((s) => s.id == 1).personCount, 3);
    expect(state.subGroups.singleWhere((s) => s.id == 2).personCount, 5);
  });

  test('a failed counts fetch still renders the local list, with counts left at their default', () async {
    when(() => repository.getSubGroups(groupId: 7, pageIndex: 1, pageSize: 200))
        .thenAnswer((_) async => const Left(NetworkFailure()));
    stubSubGroups(limit: 20, subGroups: const [subGroup1], total: 1);

    await cubit.load(7);

    final state = cubit.state as SubGroupListSuccess;
    expect(state.subGroups.single.personCount, 0);
  });

  test('emits [Loading, Error] when the local read throws', () async {
    when(() => repository.watchSubGroups(groupId: 7, search: null, limit: 20))
        .thenAnswer((_) => Stream.error(Exception('boom')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const SubGroupListLoading(), isA<SubGroupListError>()]),
    );

    await cubit.load(7);
    await expectation;
  });

  test('search debounces then resubscribes with the new filter', () async {
    stubSubGroups(limit: 20, subGroups: const [subGroup1, subGroup2], total: 2);
    await cubit.load(7);

    stubSubGroups(search: 'immediate', limit: 20, subGroups: const [subGroup1], total: 1);

    cubit.search('immediate');
    await Future.delayed(const Duration(milliseconds: 500));

    expect(cubit.state, isA<SubGroupListSuccess>().having((s) => s.subGroups, 'subGroups', [subGroup1]));
  });

  test('search on an un-loaded cubit is a no-op', () async {
    cubit.search('immediate');
    await Future.delayed(const Duration(milliseconds: 500));
    expect(cubit.state, isA<SubGroupListInitial>());
    verifyNever(() => repository.watchSubGroups(
          groupId: any(named: 'groupId'),
          search: any(named: 'search'),
          limit: any(named: 'limit'),
        ));
  });

  test('loadMore grows the limit and hasNextPage reflects the exact count', () async {
    stubSubGroups(limit: 20, subGroups: const [subGroup1], total: 2);
    await cubit.load(7);
    expect((cubit.state as SubGroupListSuccess).hasNextPage, isTrue);

    stubSubGroups(limit: 40, subGroups: const [subGroup1, subGroup2], total: 2);

    await cubit.loadMore();

    final state = cubit.state as SubGroupListSuccess;
    expect(state.subGroups, [subGroup1, subGroup2]);
    expect(state.limit, 40);
    expect(state.hasNextPage, isFalse);
  });

  test('loadMore is a no-op when hasNextPage is already false', () async {
    stubSubGroups(limit: 20, subGroups: const [subGroup1], total: 1);
    await cubit.load(7);

    await cubit.loadMore();

    verifyNever(() => repository.watchSubGroups(groupId: 7, search: any(named: 'search'), limit: 40));
  });

  test('loadMore preserves the existing items/limit and resets isLoadingMore on failure', () async {
    stubSubGroups(limit: 20, subGroups: const [subGroup1], total: 2);
    await cubit.load(7);

    when(() => repository.watchSubGroups(groupId: 7, search: null, limit: 40))
        .thenAnswer((_) => Stream.error(Exception('boom')));

    await cubit.loadMore();

    final state = cubit.state as SubGroupListSuccess;
    expect(state.subGroups, [subGroup1]);
    expect(state.limit, 20);
    expect(state.hasNextPage, isTrue);
    expect(state.isLoadingMore, isFalse);
    expect(state.loadMoreErrorMessage, isNotNull);
    expect(state.loadMoreErrorId, 1);
  });

  test('refresh re-fetches counts and resubscribes at the current search/limit without a Loading flash', () async {
    stubSubGroups(limit: 20, subGroups: const [subGroup1], total: 1);
    await cubit.load(7);

    stubSubGroups(limit: 20, subGroups: const [subGroup1, subGroup2], total: 2);

    final states = <dynamic>[];
    final sub = cubit.stream.listen(states.add);
    await cubit.refresh();
    await sub.cancel();

    expect(states, isNot(contains(isA<SubGroupListLoading>())));
    expect(cubit.state, isA<SubGroupListSuccess>().having((s) => s.subGroups, 'subGroups', [subGroup1, subGroup2]));
  });
}
