import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/network/failure.dart';
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

  const suggestion = Person(
      id: 3,
      name: 'Layla Hassan',
      gender: Gender.female,
      groupId: 1,
      groupName: 'Family',
      governorateId: 1,
      governorateName: 'Cairo',
      hasReciprocityHistory: true);
  const suggestion2 = Person(
      id: 4,
      name: 'Youssef Adel',
      gender: Gender.male,
      groupId: 2,
      groupName: 'Close friends',
      governorateId: 1,
      governorateName: 'Cairo',
      hasReciprocityHistory: true);

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

  test('loadMore appends the next page and advances pageIndex', () async {
    when(() => eventGuestRepository.getReciprocitySuggestions(1, pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [suggestion], pageIndex: 1, totalPages: 2, totalItems: 2)),
    );
    await cubit.load(1);

    when(() => eventGuestRepository.getReciprocitySuggestions(1, groupId: null, pageIndex: 2, pageSize: 20))
        .thenAnswer(
      (_) async =>
          const Right(PaginatedResult(items: [suggestion2], pageIndex: 2, totalPages: 2, totalItems: 2)),
    );

    await cubit.loadMore();

    final state = cubit.state as ReciprocitySuggestionsSuccess;
    expect(state.suggestions, [suggestion, suggestion2]);
    expect(state.pageIndex, 2);
    expect(state.hasNextPage, isFalse);
  });

  test('loadMore is a no-op when hasNextPage is already false', () async {
    when(() => eventGuestRepository.getReciprocitySuggestions(1, pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [suggestion], pageIndex: 1, totalPages: 1, totalItems: 1)),
    );
    await cubit.load(1);

    await cubit.loadMore();

    verifyNever(() => eventGuestRepository.getReciprocitySuggestions(
          1,
          groupId: any(named: 'groupId'),
          pageIndex: 2,
          pageSize: any(named: 'pageSize'),
        ));
  });

  test('loadMore ignores a second concurrent call while the first is in flight', () async {
    when(() => eventGuestRepository.getReciprocitySuggestions(1, pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [suggestion], pageIndex: 1, totalPages: 2, totalItems: 2)),
    );
    await cubit.load(1);

    final completer = Completer<Either<Failure, PaginatedResult<Person>>>();
    when(() => eventGuestRepository.getReciprocitySuggestions(1, groupId: null, pageIndex: 2, pageSize: 20))
        .thenAnswer((_) => completer.future);

    final first = cubit.loadMore();
    final second = cubit.loadMore();
    completer.complete(
      const Right(PaginatedResult(items: [suggestion2], pageIndex: 2, totalPages: 2, totalItems: 2)),
    );
    await first;
    await second;

    verify(() => eventGuestRepository.getReciprocitySuggestions(1, groupId: null, pageIndex: 2, pageSize: 20))
        .called(1);
  });

  test('loadMore preserves existing items and resets isLoadingMore on failure', () async {
    when(() => eventGuestRepository.getReciprocitySuggestions(1, pageIndex: 1, pageSize: 20)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [suggestion], pageIndex: 1, totalPages: 2, totalItems: 2)),
    );
    await cubit.load(1);

    when(() => eventGuestRepository.getReciprocitySuggestions(1, groupId: null, pageIndex: 2, pageSize: 20))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    await cubit.loadMore();

    final state = cubit.state as ReciprocitySuggestionsSuccess;
    expect(state.suggestions, [suggestion]);
    expect(state.pageIndex, 1);
    expect(state.hasNextPage, isTrue);
    expect(state.isLoadingMore, isFalse);
  });
}
