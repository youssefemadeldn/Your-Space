import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/mock/mock_data_store.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_details_cubit/person_details_cubit.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_details_cubit/person_details_state.dart';

void main() {
  late MockDataStore store;
  late PersonDetailsCubit cubit;

  setUp(() {
    store = MockDataStore()..simulatedLatency = Duration.zero;
    cubit = PersonDetailsCubit(store);
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] with the person and their occasion history', () async {
    final person = store.people().firstWhere((p) => p.hasReciprocityHistory);

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const PersonDetailsLoading(),
        isA<PersonDetailsSuccess>()
            .having((s) => s.person.id, 'person.id', person.id)
            .having((s) => s.occasions, 'occasions', isNotEmpty),
      ]),
    );

    unawaited(cubit.loadDetails(person.id));
    await expectation;
  });

  test('emits an Error when the person id does not exist', () async {
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const PersonDetailsLoading(), isA<PersonDetailsError>()]),
    );

    unawaited(cubit.loadDetails(999999));
    await expectation;
  });
}
