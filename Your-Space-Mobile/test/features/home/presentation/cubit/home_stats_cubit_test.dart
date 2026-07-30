import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/events/domain/entities/event.dart';
import 'package:your_space_mobile/features/events/domain/repositories/base_event_repository.dart';
import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';
import 'package:your_space_mobile/features/home/presentation/cubit/home_stats_cubit/home_stats_cubit.dart';
import 'package:your_space_mobile/features/home/presentation/cubit/home_stats_cubit/home_stats_state.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockPersonRepository extends Mock implements PersonRepository {}

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockGroupRepository groupRepository;
  late MockPersonRepository personRepository;
  late MockEventRepository eventRepository;
  late HomeStatsCubit cubit;

  setUp(() {
    groupRepository = MockGroupRepository();
    personRepository = MockPersonRepository();
    eventRepository = MockEventRepository();
    cubit = HomeStatsCubit(groupRepository, personRepository, eventRepository);
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] with totalItems from each list endpoint', () async {
    when(() => groupRepository.getGroups(pageIndex: 1, pageSize: 1)).thenAnswer(
      (_) async =>
          const Right(PaginatedResult(items: [Group(id: 1, name: 'Family')], pageIndex: 1, totalPages: 4, totalItems: 4)),
    );
    when(() => personRepository.getPersons(pageIndex: 1, pageSize: 1)).thenAnswer(
      (_) async => const Right(PaginatedResult(
        items: [Person(id: 1, name: 'Sara Adel', groupId: 1, groupName: 'Family')],
        pageIndex: 1,
        totalPages: 10,
        totalItems: 10,
      )),
    );
    when(() => eventRepository.getEvents(pageIndex: 1, pageSize: 1)).thenAnswer(
      (_) async => const Right(
        PaginatedResult(items: [Event(id: 1, name: 'Birthday')], pageIndex: 1, totalPages: 2, totalItems: 2),
      ),
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const HomeStatsLoading(),
        isA<HomeStatsSuccess>()
            .having((s) => s.groupsCount, 'groupsCount', 4)
            .having((s) => s.peopleCount, 'peopleCount', 10)
            .having((s) => s.eventsCount, 'eventsCount', 2),
      ]),
    );

    unawaited(cubit.load());
    await expectation;
  });

  test('emits an Error when any one of the three calls fails', () async {
    when(() => groupRepository.getGroups(pageIndex: 1, pageSize: 1))
        .thenAnswer((_) async => const Left(NetworkFailure()));
    when(() => personRepository.getPersons(pageIndex: 1, pageSize: 1)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [], pageIndex: 1, totalPages: 0, totalItems: 0)),
    );
    when(() => eventRepository.getEvents(pageIndex: 1, pageSize: 1)).thenAnswer(
      (_) async => const Right(PaginatedResult(items: [], pageIndex: 1, totalPages: 0, totalItems: 0)),
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const HomeStatsLoading(), isA<HomeStatsError>()]),
    );

    unawaited(cubit.load());
    await expectation;
  });
}
