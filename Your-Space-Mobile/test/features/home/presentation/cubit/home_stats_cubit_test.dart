import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/mock/mock_data_store.dart';
import 'package:your_space_mobile/features/home/presentation/cubit/home_stats_cubit/home_stats_cubit.dart';
import 'package:your_space_mobile/features/home/presentation/cubit/home_stats_cubit/home_stats_state.dart';

void main() {
  late MockDataStore store;
  late HomeStatsCubit cubit;

  setUp(() {
    store = MockDataStore()..simulatedLatency = Duration.zero;
    cubit = HomeStatsCubit(store);
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] with counts matching the store', () async {
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const HomeStatsLoading(),
        isA<HomeStatsSuccess>()
            .having((s) => s.groupsCount, 'groupsCount', store.groups().length)
            .having((s) => s.peopleCount, 'peopleCount', store.people().length)
            .having((s) => s.eventsCount, 'eventsCount', store.events().length),
      ]),
    );

    unawaited(cubit.load());
    await expectation;
  });
}
