import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/mock/mock_data_store.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_form_cubit/person_form_cubit.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_form_cubit/person_form_state.dart';

void main() {
  late MockDataStore store;
  late PersonFormCubit cubit;

  setUp(() {
    store = MockDataStore()..simulatedLatency = Duration.zero;
    cubit = PersonFormCubit(store);
  });

  tearDown(() => cubit.close());

  test('initialize(null) emits Ready with person null (create mode)', () {
    cubit.initialize(null);
    final state = cubit.state as PersonFormReady;
    expect(state.person, isNull);
    expect(state.availableGroups, isNotEmpty);
  });

  test('initialize(id) emits Ready pre-filled with that person (edit mode)', () {
    final person = store.people().first;
    cubit.initialize(person.id);
    final state = cubit.state as PersonFormReady;
    expect(state.person?.id, person.id);
  });

  test('submit with no personId creates a new person', () async {
    final group = store.groups().first;

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const PersonFormSubmitting(),
        isA<PersonFormSuccess>().having((s) => s.person.name, 'person.name', 'New Person'),
      ]),
    );

    unawaited(cubit.submit(name: 'New Person', groupId: group.id));
    await expectation;

    expect(store.people().map((p) => p.name), contains('New Person'));
  });

  test('submit with a personId updates the existing person', () async {
    final person = store.people().first;

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const PersonFormSubmitting(),
        isA<PersonFormSuccess>().having((s) => s.person.name, 'person.name', 'Renamed'),
      ]),
    );

    unawaited(cubit.submit(personId: person.id, name: 'Renamed', groupId: person.groupId));
    await expectation;
  });
}
