import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_guest_repository.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/reciprocity_suggestions_cubit/reciprocity_suggestions_cubit.dart';
import 'package:your_space_mobile/features/events/presentation/cubit/reciprocity_suggestions_cubit/reciprocity_suggestions_state.dart';
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';

class MockEventGuestRepository extends Mock implements EventGuestRepository {}

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockEventGuestRepository eventGuestRepository;
  late MockGroupRepository groupRepository;
  late ReciprocitySuggestionsCubit cubit;

  const suggestion =
      Person(id: 3, name: 'Layla Hassan', groupId: 1, groupName: 'Family', hasReciprocityHistory: true);

  setUp(() {
    eventGuestRepository = MockEventGuestRepository();
    groupRepository = MockGroupRepository();
    cubit = ReciprocitySuggestionsCubit(eventGuestRepository, groupRepository);

    when(() => groupRepository.getGroups(pageIndex: 1, pageSize: 50))
        .thenAnswer((_) async => const Right(PaginatedResult(items: [], pageIndex: 1, totalPages: 1, totalItems: 0)));
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] with reciprocity suggestions for the event', () async {
    when(() => eventGuestRepository.getReciprocitySuggestions(1, pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [suggestion], pageIndex: 1, totalPages: 1, totalItems: 1)),
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const ReciprocitySuggestionsLoading(),
        isA<ReciprocitySuggestionsSuccess>().having((s) => s.suggestions, 'suggestions', [suggestion]),
      ]),
    );

    unawaited(cubit.load(1));
    await expectation;
  });

  test('refresh re-queries page 1 without emitting a Loading state', () async {
    when(() => eventGuestRepository.getReciprocitySuggestions(1, pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [suggestion], pageIndex: 1, totalPages: 1, totalItems: 1)),
    );
    await cubit.load(1);

    when(() => eventGuestRepository.getReciprocitySuggestions(1, groupId: null, pageIndex: 1, pageSize: 20))
        .thenAnswer((_) async => const Right(PaginatedResult(items: [], pageIndex: 1, totalPages: 1, totalItems: 0)));

    // emits() matches exactly the next single emission — if refresh emitted
    // Loading first, this would fail on that mismatch.
    final expectation = expectLater(cubit.stream, emits(isA<ReciprocitySuggestionsSuccess>()));
    unawaited(cubit.refresh());
    await expectation;
  });
}
