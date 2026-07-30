import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/invite_method.dart';
import 'package:your_space_mobile/features/people/domain/entities/person_occasion_history_entry.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/add_occasion_cubit/add_occasion_cubit.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/add_occasion_cubit/add_occasion_state.dart';

class MockPersonRepository extends Mock implements PersonRepository {}

void main() {
  late MockPersonRepository repository;
  late AddOccasionCubit cubit;

  setUp(() {
    repository = MockPersonRepository();
    cubit = AddOccasionCubit(repository);
  });

  tearDown(() => cubit.close());

  test('submit emits [Submitting, Success] with the created entry', () async {
    when(() => repository.addOccasionHistory(
          personId: any(named: 'personId'),
          invitedMe: any(named: 'invitedMe'),
          inviteMethod: any(named: 'inviteMethod'),
          occasionName: any(named: 'occasionName'),
          occasionDate: any(named: 'occasionDate'),
          notes: any(named: 'notes'),
        )).thenAnswer(
      (_) async => Right(PersonOccasionHistoryEntry(
        id: 1,
        personId: 1,
        invitedMe: true,
        inviteMethod: InviteMethod.whatsApp,
        occasionName: 'Dinner',
        createdAt: DateTime(2026),
      )),
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const AddOccasionSubmitting(),
        isA<AddOccasionSuccess>().having((s) => s.entry.occasionName, 'occasionName', 'Dinner'),
      ]),
    );

    unawaited(cubit.submit(
      personId: 1,
      invitedMe: true,
      inviteMethod: InviteMethod.whatsApp,
      occasionName: 'Dinner',
    ));
    await expectation;
  });
}
