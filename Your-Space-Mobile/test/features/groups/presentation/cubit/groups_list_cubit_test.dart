import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/mock/mock_data_store.dart';
import 'package:your_space_mobile/features/groups/presentation/cubit/groups_list_cubit/groups_list_cubit.dart';
import 'package:your_space_mobile/features/groups/presentation/cubit/groups_list_cubit/groups_list_state.dart';

void main() {
  late MockDataStore store;
  late GroupsListCubit cubit;

  setUp(() {
    store = MockDataStore()..simulatedLatency = Duration.zero;
    cubit = GroupsListCubit(store);
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] with all groups on load', () async {
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const GroupsListLoading(),
        isA<GroupsListSuccess>().having((s) => s.groups.length, 'groups.length', store.groups().length),
      ]),
    );

    unawaited(cubit.load());
    await expectation;
  });

  test('search filters the list without a Loading flash', () async {
    await cubit.load();

    final expectation = expectLater(
      cubit.stream,
      emits(isA<GroupsListSuccess>().having((s) => s.groups.length, 'groups.length', 1)),
    );

    cubit.search('fam');
    await expectation;
  });

  test('search on an un-loaded cubit is a no-op', () {
    cubit.search('fam');
    expect(cubit.state, isA<GroupsListInitial>());
  });
}
