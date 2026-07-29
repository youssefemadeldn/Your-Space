import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/mock/mock_data_store.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/people_list_cubit/people_list_cubit.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/people_list_cubit/people_list_state.dart';

void main() {
  late MockDataStore store;
  late PeopleListCubit cubit;

  setUp(() {
    store = MockDataStore()..simulatedLatency = Duration.zero;
    cubit = PeopleListCubit(store);
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] with all people and groups on load', () async {
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const PeopleListLoading(),
        isA<PeopleListSuccess>()
            .having((s) => s.people.length, 'people.length', store.people().length)
            .having((s) => s.groups.length, 'groups.length', store.groups().length),
      ]),
    );

    unawaited(cubit.load());
    await expectation;
  });

  test('filterByGroup narrows the list to that group and tracks selectedGroupId', () async {
    await cubit.load();
    final family = store.groups().firstWhere((g) => g.name == 'Family');

    final expectation = expectLater(
      cubit.stream,
      emits(
        isA<PeopleListSuccess>()
            .having((s) => s.selectedGroupId, 'selectedGroupId', family.id)
            .having((s) => s.people.every((p) => p.groupId == family.id), 'all in group', true),
      ),
    );

    cubit.filterByGroup(family.id);
    await expectation;
  });
}
