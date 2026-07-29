import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/mock/mock_data_store.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/reciprocity_suggestions_cubit/reciprocity_suggestions_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/reciprocity_suggestions_cubit/reciprocity_suggestions_state.dart';

void main() {
  late MockDataStore store;
  late ReciprocitySuggestionsCubit cubit;

  setUp(() {
    store = MockDataStore()..simulatedLatency = Duration.zero;
    cubit = ReciprocitySuggestionsCubit(store);
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] with reciprocity suggestions for the event', () async {
    final event = store.events().firstWhere((e) => e.name == "Sara's Birthday");

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const ReciprocitySuggestionsLoading(),
        isA<ReciprocitySuggestionsSuccess>()
            .having((s) => s.suggestions, 'suggestions', store.reciprocitySuggestions(event.id)),
      ]),
    );

    unawaited(cubit.load(event.id));
    await expectation;
  });

  test('refresh re-queries without emitting a Loading state', () async {
    final event = store.events().firstWhere((e) => e.name == "Sara's Birthday");
    await cubit.load(event.id);

    // Cubit.emit() skips re-emitting an Equatable-equal state, so the store
    // must actually change first — adding one of the current suggestions as
    // a guest removes them from the recomputed list, giving refresh()
    // something genuinely different to emit.
    final suggestion = store.reciprocitySuggestions(event.id).first;
    store.addPersonsToEvent(eventId: event.id, personIds: [suggestion.id]);

    // emits() matches exactly the next single emission — if refresh emitted
    // Loading first, this would fail on that mismatch.
    final expectation = expectLater(cubit.stream, emits(isA<ReciprocitySuggestionsSuccess>()));
    cubit.refresh();
    await expectation;
  });
}
