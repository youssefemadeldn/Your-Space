import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/mock/entities/invite_method.dart';
import 'package:your_space_mobile/core/mock/mock_data_store.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/add_occasion_cubit/add_occasion_cubit.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/add_occasion_cubit/add_occasion_state.dart';

void main() {
  late MockDataStore store;
  late AddOccasionCubit cubit;

  setUp(() {
    store = MockDataStore()..simulatedLatency = Duration.zero;
    cubit = AddOccasionCubit(store);
  });

  tearDown(() => cubit.close());

  test('submit emits [Submitting, Success] and records the entry', () async {
    final person = store.people().first;

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const AddOccasionSubmitting(),
        isA<AddOccasionSuccess>().having((s) => s.entry.occasionName, 'occasionName', 'Dinner'),
      ]),
    );

    unawaited(cubit.submit(
      personId: person.id,
      invitedMe: true,
      inviteMethod: InviteMethod.whatsApp,
      occasionName: 'Dinner',
    ));
    await expectation;

    expect(store.occasionHistory(person.id).any((e) => e.occasionName == 'Dinner'), isTrue);
  });
}
