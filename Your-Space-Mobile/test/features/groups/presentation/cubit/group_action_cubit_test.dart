import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/mock/mock_data_store.dart';
import 'package:your_space_mobile/features/groups/presentation/cubit/group_action_cubit/group_action_cubit.dart';
import 'package:your_space_mobile/features/groups/presentation/cubit/group_action_cubit/group_action_state.dart';

void main() {
  late MockDataStore store;
  late GroupActionCubit cubit;

  setUp(() {
    store = MockDataStore()..simulatedLatency = Duration.zero;
    cubit = GroupActionCubit(store);
  });

  tearDown(() => cubit.close());

  test('createGroup emits [Submitting, Success] and adds it to the store', () async {
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const GroupActionSubmitting(),
        isA<GroupActionSuccess>().having((s) => s.group.name, 'group.name', 'Book club'),
      ]),
    );

    unawaited(cubit.createGroup(name: 'Book club'));
    await expectation;

    expect(store.groups().map((g) => g.name), contains('Book club'));
  });

  test('updateGroup emits [Submitting, Success] with the renamed group', () async {
    final family = store.groups().firstWhere((g) => g.name == 'Family');

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const GroupActionSubmitting(),
        isA<GroupActionSuccess>().having((s) => s.group.name, 'group.name', 'The Family'),
      ]),
    );

    unawaited(cubit.updateGroup(id: family.id, name: 'The Family'));
    await expectation;
  });
}
