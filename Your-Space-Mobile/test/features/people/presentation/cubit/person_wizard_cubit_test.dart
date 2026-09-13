import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/governorate.dart';
import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/entities/person_image.dart';
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
    List<Group>? groups,
    Either<Failure, PaginatedResult<Governorate>>? governorates,
  }) {
    when(() => groupRepository.watchGroups(limit: any(named: 'limit')))
        .thenAnswer((_) => Stream.value(groups ?? const [Group(id: 1, name: 'Family')]));
    when(() => governorateRepository.getGovernorates(
          pageIndex: any(named: 'pageIndex'),
          pageSize: any(named: 'pageSize'),
        )).thenAnswer((_) async => governorates ?? Right(_page(const [Governorate(id: 1, name: 'Cairo')])));
  }

  setUpAll(() {
    registerFallbackValue(Gender.male);
    registerFallbackValue(File(''));
  });

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

    test('emits Ready with an empty group picker when the local cache has no groups yet', () async {
      stubReferenceLists(groups: const []);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const PersonWizardLoading(),
          isA<PersonWizardReady>().having((s) => s.availableGroups, 'availableGroups', isEmpty),
        ]),
      );

      unawaited(cubit.initialize(null));
      await expectation;
    });

    test('surfaces an error screen when the governorate list fails (no silent empty picker)', () async {
      stubReferenceLists(governorates: const Left(NetworkFailure()));

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

  group('submit', () {
    Future<void> readyForSubmit() async {
      stubReferenceLists();
      await cubit.initialize(null);
      when(() => subGroupRepository.getSubGroups(
            groupId: any(named: 'groupId'),
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => Right(_page(const [])));
      when(() => cityRepository.getCities(
            governorateId: any(named: 'governorateId'),
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => Right(_page(const [])));
      await cubit.selectGroup(1);
      await cubit.selectGovernorate(1);
      cubit.updateName('New Person');
      cubit.updateGender(Gender.male);
    }

    test('with no photo/relationship changes calls createPerson (not AndSync) and skips child syncs', () async {
      await readyForSubmit();
      when(() => personRepository.createPerson(
            name: any(named: 'name'),
            phoneNumber: any(named: 'phoneNumber'),
            phoneNumber2: any(named: 'phoneNumber2'),
            gender: any(named: 'gender'),
            groupId: any(named: 'groupId'),
            groupName: any(named: 'groupName'),
            subGroupId: any(named: 'subGroupId'),
            subGroupName: any(named: 'subGroupName'),
            governorateId: any(named: 'governorateId'),
            governorateName: any(named: 'governorateName'),
            cityId: any(named: 'cityId'),
            cityName: any(named: 'cityName'),
            neighborhoodId: any(named: 'neighborhoodId'),
            neighborhoodName: any(named: 'neighborhoodName'),
            notes: any(named: 'notes'),
          )).thenAnswer((_) async => const Right(_person));

      await cubit.submit();

      final captured = verify(() => personRepository.createPerson(
            name: 'New Person',
            phoneNumber: any(named: 'phoneNumber'),
            phoneNumber2: any(named: 'phoneNumber2'),
            gender: Gender.male,
            groupId: 1,
            groupName: captureAny(named: 'groupName'),
            subGroupId: any(named: 'subGroupId'),
            subGroupName: any(named: 'subGroupName'),
            governorateId: 1,
            governorateName: captureAny(named: 'governorateName'),
            cityId: any(named: 'cityId'),
            cityName: any(named: 'cityName'),
            neighborhoodId: any(named: 'neighborhoodId'),
            neighborhoodName: any(named: 'neighborhoodName'),
            notes: any(named: 'notes'),
          )).captured;
      expect(captured, ['Family', 'Cairo']);

      expect(cubit.state, isA<PersonWizardSubmitSuccess>());
      verifyNever(() => personRepository.createPersonAndSync(
            name: any(named: 'name'),
            gender: any(named: 'gender'),
            groupId: any(named: 'groupId'),
            groupName: any(named: 'groupName'),
            governorateId: any(named: 'governorateId'),
            governorateName: any(named: 'governorateName'),
          ));
      verifyZeroInteractions(personImageRepository);
      verifyZeroInteractions(personRelationshipRepository);
    });

    test('with a staged new photo calls createPersonAndSync and still runs photo sync on success', () async {
      await readyForSubmit();
      cubit.addPhoto(File('local.jpg'));

      when(() => personRepository.createPersonAndSync(
            name: any(named: 'name'),
            phoneNumber: any(named: 'phoneNumber'),
            phoneNumber2: any(named: 'phoneNumber2'),
            gender: any(named: 'gender'),
            groupId: any(named: 'groupId'),
            groupName: any(named: 'groupName'),
            subGroupId: any(named: 'subGroupId'),
            subGroupName: any(named: 'subGroupName'),
            governorateId: any(named: 'governorateId'),
            governorateName: any(named: 'governorateName'),
            cityId: any(named: 'cityId'),
            cityName: any(named: 'cityName'),
            neighborhoodId: any(named: 'neighborhoodId'),
            neighborhoodName: any(named: 'neighborhoodName'),
            notes: any(named: 'notes'),
          )).thenAnswer((_) async => const Right(_person));
      when(() => personImageRepository.uploadImage(personId: any(named: 'personId'), file: any(named: 'file')))
          .thenAnswer((_) async => const Right(PersonImage(id: 1, url: 'https://x/1.jpg', isPrimary: true)));
      when(() => personImageRepository.setPrimary(personId: any(named: 'personId'), imageId: any(named: 'imageId')))
          .thenAnswer((_) async => const Right(PersonImage(id: 1, url: 'https://x/1.jpg', isPrimary: true)));

      await cubit.submit();

      verify(() => personRepository.createPersonAndSync(
            name: any(named: 'name'),
            phoneNumber: any(named: 'phoneNumber'),
            phoneNumber2: any(named: 'phoneNumber2'),
            gender: any(named: 'gender'),
            groupId: any(named: 'groupId'),
            groupName: any(named: 'groupName'),
            subGroupId: any(named: 'subGroupId'),
            subGroupName: any(named: 'subGroupName'),
            governorateId: any(named: 'governorateId'),
            governorateName: any(named: 'governorateName'),
            cityId: any(named: 'cityId'),
            cityName: any(named: 'cityName'),
            neighborhoodId: any(named: 'neighborhoodId'),
            neighborhoodName: any(named: 'neighborhoodName'),
            notes: any(named: 'notes'),
          )).called(1);
      verify(() => personImageRepository.uploadImage(personId: _person.id, file: any(named: 'file'))).called(1);
      expect(cubit.state, isA<PersonWizardSubmitSuccess>());
    });

    test('with a photo change, a failed immediate sync emits submitError and skips child syncs', () async {
      await readyForSubmit();
      cubit.addPhoto(File('local.jpg'));
      const failure = NetworkFailure();

      when(() => personRepository.createPersonAndSync(
            name: any(named: 'name'),
            phoneNumber: any(named: 'phoneNumber'),
            phoneNumber2: any(named: 'phoneNumber2'),
            gender: any(named: 'gender'),
            groupId: any(named: 'groupId'),
            groupName: any(named: 'groupName'),
            subGroupId: any(named: 'subGroupId'),
            subGroupName: any(named: 'subGroupName'),
            governorateId: any(named: 'governorateId'),
            governorateName: any(named: 'governorateName'),
            cityId: any(named: 'cityId'),
            cityName: any(named: 'cityName'),
            neighborhoodId: any(named: 'neighborhoodId'),
            neighborhoodName: any(named: 'neighborhoodName'),
            notes: any(named: 'notes'),
          )).thenAnswer((_) async => const Left(failure));

      await cubit.submit();

      final state = cubit.state as PersonWizardReady;
      expect(state.isSubmitting, isFalse);
      expect(state.submitError, isNotNull);
      verifyZeroInteractions(personImageRepository);
    });
  });
}
