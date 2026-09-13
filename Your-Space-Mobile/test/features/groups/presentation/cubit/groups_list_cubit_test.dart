import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';
import 'package:your_space_mobile/features/groups/presentation/cubit/groups_list_cubit/groups_list_cubit.dart';
import 'package:your_space_mobile/features/groups/presentation/cubit/groups_list_cubit/groups_list_state.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockGroupRepository repository;
  late GroupsListCubit cubit;

  const group1 = Group(id: 1, name: 'Family');
  const group2 = Group(id: 2, name: 'Close friends');

  /// Stubs a `watchGroups`/`countGroups` pair for a given search/limit.
  void stubGroups({String? search, required int limit, required List<Group> groups, required int total}) {
    when(() => repository.watchGroups(search: search, limit: limit)).thenAnswer((_) => Stream.value(groups));
    when(() => repository.countGroups(search: search)).thenAnswer((_) async => total);
  }

  setUp(() {
    repository = MockGroupRepository();
    cubit = GroupsListCubit(repository);
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] with the first window on load', () async {
    stubGroups(limit: 20, groups: const [group1, group2], total: 2);

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const GroupsListLoading(),
        isA<GroupsListSuccess>()
            .having((s) => s.groups.length, 'groups.length', 2)
            .having((s) => s.hasNextPage, 'hasNextPage', false),
      ]),
    );

    await cubit.load();
    await expectation;
  });

  test('emits [Loading, Error] when the local read throws', () async {
    when(() => repository.watchGroups(search: null, limit: 20)).thenAnswer((_) => Stream.error(Exception('boom')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const GroupsListLoading(), isA<GroupsListError>()]),
    );

    await cubit.load();
    await expectation;
  });

  test('search debounces then resubscribes with the new filter', () async {
    stubGroups(limit: 20, groups: const [group1, group2], total: 2);
    await cubit.load();

    stubGroups(search: 'fam', limit: 20, groups: const [group1], total: 1);

    cubit.search('fam');
    await Future.delayed(const Duration(milliseconds: 500));

    expect(cubit.state, isA<GroupsListSuccess>().having((s) => s.groups, 'groups', [group1]));
  });

  test('search on an un-loaded cubit is a no-op', () async {
    cubit.search('fam');
    await Future.delayed(const Duration(milliseconds: 500));
    expect(cubit.state, isA<GroupsListInitial>());
    verifyNever(() => repository.watchGroups(search: any(named: 'search'), limit: any(named: 'limit')));
  });

  test('loadMore grows the limit and hasNextPage reflects the exact count', () async {
    stubGroups(limit: 20, groups: const [group1], total: 2);
    await cubit.load();
    expect((cubit.state as GroupsListSuccess).hasNextPage, isTrue);

    stubGroups(limit: 40, groups: const [group1, group2], total: 2);

    await cubit.loadMore();

    final state = cubit.state as GroupsListSuccess;
    expect(state.groups, [group1, group2]);
    expect(state.limit, 40);
    expect(state.hasNextPage, isFalse);
  });

  test('loadMore is a no-op when hasNextPage is already false', () async {
    stubGroups(limit: 20, groups: const [group1], total: 1);
    await cubit.load();

    await cubit.loadMore();

    verifyNever(() => repository.watchGroups(search: any(named: 'search'), limit: 40));
  });

  test('loadMore ignores a second concurrent call while the first is in flight', () async {
    stubGroups(limit: 20, groups: const [group1], total: 2);
    await cubit.load();

    final controller = StreamController<List<Group>>();
    when(() => repository.watchGroups(search: null, limit: 40)).thenAnswer((_) => controller.stream);
    when(() => repository.countGroups(search: null)).thenAnswer((_) async => 2);

    final first = cubit.loadMore();
    final second = cubit.loadMore();
    controller.add(const [group1, group2]);
    await controller.close();
    await first;
    await second;

    verify(() => repository.watchGroups(search: null, limit: 40)).called(1);
  });

  test('loadMore preserves the existing items/limit and resets isLoadingMore on failure', () async {
    stubGroups(limit: 20, groups: const [group1], total: 2);
    await cubit.load();

    when(() => repository.watchGroups(search: null, limit: 40)).thenAnswer((_) => Stream.error(Exception('boom')));

    await cubit.loadMore();

    final state = cubit.state as GroupsListSuccess;
    expect(state.groups, [group1]);
    expect(state.limit, 20);
    expect(state.hasNextPage, isTrue);
    expect(state.isLoadingMore, isFalse);
    expect(state.loadMoreErrorMessage, isNotNull);
    expect(state.loadMoreErrorId, 1);
  });

  test('refresh resubscribes at the current search/limit without a Loading flash', () async {
    stubGroups(limit: 20, groups: const [group1], total: 1);
    await cubit.load();

    stubGroups(limit: 20, groups: const [group1, group2], total: 2);

    final states = <dynamic>[];
    final sub = cubit.stream.listen(states.add);
    await cubit.refresh();
    await sub.cancel();

    expect(states, isNot(contains(isA<GroupsListLoading>())));
    expect(cubit.state, isA<GroupsListSuccess>().having((s) => s.groups, 'groups', [group1, group2]));
  });
}
