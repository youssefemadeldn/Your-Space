import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/governorate.dart';
import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/entities/relation_type.dart';
import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_city_repository.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_governorate_repository.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_neighborhood_repository.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_subgroup_repository.dart';
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_image_repository.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_relationship_repository.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_wizard_cubit/person_wizard_cubit.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_wizard_cubit/person_wizard_state.dart';

class MockPersonRepository extends Mock implements PersonRepository {}

class MockGroupRepository extends Mock implements GroupRepository {}

class MockSubGroupRepository extends Mock implements SubGroupRepository {}

class MockGovernorateRepository extends Mock implements GovernorateRepository {}

class MockCityRepository extends Mock implements CityRepository {}

class MockNeighborhoodRepository extends Mock implements NeighborhoodRepository {}

class MockPersonImageRepository extends Mock implements PersonImageRepository {}

class MockPersonRelationshipRepository extends Mock implements PersonRelationshipRepository {}

PaginatedResult<T> _page<T>(List<T> items) =>
    PaginatedResult(items: items, pageIndex: 1, totalPages: 1, totalItems: items.length);

const _person = Person(
  id: 7,
  name: 'Sara Adel',
  gender: Gender.female,
  groupId: 1,
  groupName: 'Family',
  governorateId: 1,
  governorateName: 'Cairo',
);

void main() {
  late MockPersonRepository personRepository;
  late MockGroupRepository groupRepository;
  late MockSubGroupRepository subGroupRepository;
  late MockGovernorateRepository governorateRepository;
  late MockCityRepository cityRepository;
  late MockNeighborhoodRepository neighborhoodRepository;
  late MockPersonImageRepository personImageRepository;
  late MockPersonRelationshipRepository personRelationshipRepository;
  late DataRefreshBus dataRefreshBus;
  late PersonWizardCubit cubit;

  PersonWizardCubit build() => PersonWizardCubit(
        personRepository,
        groupRepository,
        subGroupRepository,
        governorateRepository,
        cityRepository,
        neighborhoodRepository,
        personImageRepository,
        personRelationshipRepository,
        dataRefreshBus,
      );

  void stubReferenceLists({
    Either<Failure, PaginatedResult<Group>>? groups,
    Either<Failure, PaginatedResult<Governorate>>? governorates,
  }) {
    when(() => groupRepository.getGroups(pageIndex: any(named: 'pageIndex'), pageSize: any(named: 'pageSize')))
        .thenAnswer((_) async => groups ?? Right(_page(const [Group(id: 1, name: 'Family')])));
    when(() => governorateRepository.getGovernorates(
          pageIndex: any(named: 'pageIndex'),
          pageSize: any(named: 'pageSize'),
        )).thenAnswer((_) async => governorates ?? Right(_page(const [Governorate(id: 1, name: 'Cairo')])));
  }

  setUp(() {
    personRepository = MockPersonRepository();
    groupRepository = MockGroupRepository();
    subGroupRepository = MockSubGroupRepository();
    governorateRepository = MockGovernorateRepository();
    cityRepository = MockCityRepository();
    neighborhoodRepository = MockNeighborhoodRepository();
    personImageRepository = MockPersonImageRepository();
    personRelationshipRepository = MockPersonRelationshipRepository();
    dataRefreshBus = DataRefreshBus();
    cubit = build();
  });

  tearDown(() => cubit.close());

  group('initialize (Add mode)', () {
    test('emits [Loading, Ready] with the fetched group + governorate lists', () async {
      stubReferenceLists();

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const PersonWizardLoading(),
          isA<PersonWizardReady>()
              .having((s) => s.availableGroups.single.id, 'group', 1)
              .having((s) => s.availableGovernorates.single.id, 'governorate', 1)
              .having((s) => s.isEditing, 'isEditing', false),
        ]),
      );

      unawaited(cubit.initialize(null));
      await expectation;
    });

    test('surfaces an error screen when the group list fails (no silent empty picker)', () async {
      stubReferenceLists(groups: const Left(NetworkFailure()));

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([const PersonWizardLoading(), isA<PersonWizardError>()]),
      );

      unawaited(cubit.initialize(null));
      await expectation;
    });
  });

  group('validateStep(2) — relationship completeness', () {
    setUp(() async {
      stubReferenceLists();
      await cubit.initialize(null);
    });

    test('null when there are no rows', () {
      expect(cubit.validateStep(2), isNull);
    });

    test('null for a fully-empty row', () {
      cubit.addRelationshipRow();
      expect(cubit.validateStep(2), isNull);
    });

    test('returns the incomplete key when only the relation type is set', () {
      cubit.addRelationshipRow();
      final rowId = (cubit.state as PersonWizardReady).relationshipRows.single.localId;
      cubit.updateRelationshipType(rowId, RelationType.sister);

      expect(cubit.validateStep(2), 'people.wizard.step3.incompleteRelationship');
    });

    test('null again once the person is also chosen', () {
      cubit.addRelationshipRow();
      final rowId = (cubit.state as PersonWizardReady).relationshipRows.single.localId;
      cubit.updateRelationshipType(rowId, RelationType.sister);
      cubit.updateRelationshipPerson(rowId, 7, 'Sara Adel');

      expect(cubit.validateStep(2), isNull);
    });
  });

  group('searchRelationshipPeople', () {
    setUp(() async {
      stubReferenceLists();
      await cubit.initialize(null);
    });

    test('debounces, then emits server results into relationshipLookupResults', () async {
      when(() => personRepository.getPersons(
            search: any(named: 'search'),
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => Right(_page(const [_person])));

      cubit.searchRelationshipPeople('sara');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final state = cubit.state as PersonWizardReady;
      expect(state.relationshipLookupLoading, isFalse);
      expect(state.relationshipLookupResults.single.id, 7);
      verify(() => personRepository.getPersons(
            search: 'sara',
            pageIndex: 1,
            pageSize: any(named: 'pageSize'),
          )).called(1);
    });
  });

  group('addGroupInline', () {
    setUp(() async {
      stubReferenceLists();
      await cubit.initialize(null);
    });

    test('creates the group, selects it, appends it, and pings the refresh bus', () async {
      when(() => groupRepository.createGroup(name: any(named: 'name')))
          .thenAnswer((_) async => const Right(Group(id: 99, name: 'Neighbours')));
      when(() => subGroupRepository.getSubGroups(
            groupId: any(named: 'groupId'),
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => Right(_page(const [])));

      final scopes = <DataScope>[];
      final sub = dataRefreshBus.stream.listen(scopes.add);

      final newId = await cubit.addGroupInline('Neighbours');
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(newId, 99);
      final state = cubit.state as PersonWizardReady;
      expect(state.groupId, 99);
      expect(state.availableGroups.map((g) => g.id), containsAll(<int>[1, 99]));
      expect(scopes, contains(DataScope.groups));
    });
  });
}
