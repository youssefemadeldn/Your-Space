import 'dart:io';

import 'package:flutter/foundation.dart' show UniqueKey;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/city.dart';
import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/governorate.dart';
import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/entities/neighborhood.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/entities/person_image.dart';
import 'package:your_space_mobile/core/entities/relation_type.dart';
import 'package:your_space_mobile/core/entities/subgroup.dart';
import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/classification/domain/repositories/base_city_repository.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_governorate_repository.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_neighborhood_repository.dart';
import 'package:your_space_mobile/features/classification/domain/repositories/base_subgroup_repository.dart';
import 'package:your_space_mobile/features/groups/domain/repositories/base_group_repository.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_image_repository.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_relationship_repository.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';

import 'draft_relationship_row.dart';
import 'person_wizard_state.dart';
import 'staged_person_photo.dart';

// Local-only widget/list-item identity — never sent to the backend, so a
// cryptographically unique id isn't needed. UniqueKey() avoids pulling in a
// new package dependency just for this.
String _newLocalId() => UniqueKey().toString();

/// One cubit for the whole 4-step wizard — a direct evolution of the
/// single-cubit `PersonFormCubit` precedent with more draft fields/steps,
/// not a list-plus-concurrent-mutation screen (Rule 5's actual trigger for
/// splitting cubits). All photo/relationship mutations are staged locally
/// (see `StagedPersonPhoto`/`DraftRelationshipRow`) — nothing hits the
/// network until [submit].
@injectable
class PersonWizardCubit extends Cubit<PersonWizardState> {
  final PersonRepository _personRepository;
  final GroupRepository _groupRepository;
  final SubGroupRepository _subGroupRepository;
  final GovernorateRepository _governorateRepository;
  final CityRepository _cityRepository;
  final NeighborhoodRepository _neighborhoodRepository;
  final PersonImageRepository _personImageRepository;
  final PersonRelationshipRepository _personRelationshipRepository;
  final DataRefreshBus _dataRefreshBus;

  PersonWizardCubit(
    this._personRepository,
    this._groupRepository,
    this._subGroupRepository,
    this._governorateRepository,
    this._cityRepository,
    this._neighborhoodRepository,
    this._personImageRepository,
    this._personRelationshipRepository,
    this._dataRefreshBus,
  ) : super(const PersonWizardInitial());

  Future<void> initialize(int? personId) async {
    emit(const PersonWizardLoading());

    final groupsResult = await _groupRepository.getGroups(pageIndex: 1, pageSize: 50);
    final governoratesResult = await _governorateRepository.getGovernorates(pageIndex: 1, pageSize: 50);
    final peopleResult = await _personRepository.getPersons(pageIndex: 1, pageSize: 200);

    final groups = groupsResult.fold((_) => const <Group>[], (page) => page.items);
    final governorates = governoratesResult.fold((_) => const <Governorate>[], (page) => page.items);
    final allPeople = peopleResult.fold((_) => const <Person>[], (page) => page.items);

    if (personId == null) {
      emit(PersonWizardReady(
        availableGroups: groups,
        availableGovernorates: governorates,
        peopleForLookup: allPeople,
      ));
      return;
    }

    final detailsResult = await _personRepository.getPersonById(personId);
    await detailsResult.fold(
      (failure) async => emit(PersonWizardError(core.failureToMessage(failure))),
      (details) async {
        final person = details.person;
        final peopleForLookup = allPeople.where((p) => p.id != personId).toList();

        // Pre-seed the staged photo grid from the person's existing PersonImage rows.
        final imagesResult = await _personImageRepository.getImages(personId);
        final images = imagesResult.fold((_) => const <PersonImage>[], (list) => list);
        final stagedPhotos = images
            .map((img) => StagedPersonPhoto(
                  localId: _newLocalId(),
                  existingImageId: img.id,
                  existingUrl: img.url,
                  isPrimary: img.isPrimary,
                ))
            .toList();

        final relationshipRows = details.relationships
            .map((r) => DraftRelationshipRow(
                  localId: _newLocalId(),
                  relationType: r.relationType,
                  relatedPersonId: r.relatedPersonId,
                  relatedPersonName: r.relatedPersonName,
                  existingRelationshipId: r.id,
                  originalRelationType: r.relationType,
                  originalRelatedPersonId: r.relatedPersonId,
                ))
            .toList();

        var ready = PersonWizardReady(
          personId: personId,
          name: person.name,
          phoneNumber: person.phoneNumber ?? '',
          phoneNumber2: person.phoneNumber2 ?? '',
          gender: person.gender,
          stagedPhotos: stagedPhotos,
          groupId: person.groupId,
          subGroupId: person.subGroupId,
          governorateId: person.governorateId,
          cityId: person.cityId,
          neighborhoodId: person.neighborhoodId,
          availableGroups: groups,
          availableGovernorates: governorates,
          relationshipRows: relationshipRows,
          peopleForLookup: peopleForLookup,
          notes: person.notes ?? '',
          originalPhotoIds: images.map((i) => i.id).toSet(),
          originalRelationshipIds: details.relationships.map((r) => r.id).toSet(),
        );

        // Cascade-preload the pickers so an edit view shows the right options already.
        final subGroupsResult =
            await _subGroupRepository.getSubGroups(groupId: person.groupId, pageIndex: 1, pageSize: 50);
        ready = ready.copyWith(
          availableSubGroups: subGroupsResult.fold((_) => const <SubGroup>[], (p) => p.items),
        );

        final citiesResult = await _cityRepository.getCities(
          governorateId: person.governorateId,
          pageIndex: 1,
          pageSize: 50,
        );
        ready = ready.copyWith(availableCities: citiesResult.fold((_) => const <City>[], (p) => p.items));

        if (person.cityId != null) {
          final neighborhoodsResult =
              await _neighborhoodRepository.getNeighborhoods(cityId: person.cityId!, pageIndex: 1, pageSize: 50);
          ready = ready.copyWith(
            availableNeighborhoods: neighborhoodsResult.fold((_) => const <Neighborhood>[], (p) => p.items),
          );
        }

        emit(ready);
      },
    );
  }

  // ---- Step navigation (pure — reads state, no emit) ----

  /// Returns an error message if [step] (0-indexed) isn't complete enough to
  /// advance past, or null if it's valid. The screen shows the message via a
  /// snackbar and keeps the user on the current page.
  String? validateStep(int step) {
    final current = state;
    if (current is! PersonWizardReady) return null;
    switch (step) {
      case 0:
        if (current.name.trim().isEmpty) return 'people.wizard.step1.nameRequired';
        if (current.gender == null) return 'people.wizard.step1.genderRequired';
        return null;
      case 1:
        if (current.groupId == null) return 'people.wizard.step2.groupRequired';
        if (current.governorateId == null) return 'people.wizard.step2.governorateRequired';
        return null;
      default:
        return null;
    }
  }

  // ---- Step 1 — Basic Identity ----

  void updateName(String value) => _updateReady((r) => r.copyWith(name: value));
  void updatePhoneNumber(String value) => _updateReady((r) => r.copyWith(phoneNumber: value));
  void updatePhoneNumber2(String value) => _updateReady((r) => r.copyWith(phoneNumber2: value));
  void updateGender(Gender value) => _updateReady((r) => r.copyWith(gender: value));

  void addPhoto(File file) => _updateReady((r) {
        if (r.stagedPhotos.length >= 6) return r;
        final photo = StagedPersonPhoto(
          localId: _newLocalId(),
          localFile: file,
          isPrimary: r.stagedPhotos.isEmpty,
        );
        return r.copyWith(stagedPhotos: [...r.stagedPhotos, photo]);
      });

  void removePhoto(String localId) => _updateReady((r) {
        final removed = r.stagedPhotos.firstWhere((p) => p.localId == localId);
        final remaining = r.stagedPhotos.where((p) => p.localId != localId).toList();
        if (removed.isPrimary && remaining.isNotEmpty) {
          remaining[0] = remaining[0].copyWith(isPrimary: true);
        }
        return r.copyWith(stagedPhotos: remaining);
      });

  void markPrimary(String localId) => _updateReady((r) => r.copyWith(
        stagedPhotos: r.stagedPhotos.map((p) => p.copyWith(isPrimary: p.localId == localId)).toList(),
      ));

  // ---- Step 2 — Classification & Location ----

  Future<void> selectGroup(int groupId) async {
    _updateReady((r) => r.copyWith(groupId: groupId, clearSubGroup: true));
    final result = await _subGroupRepository.getSubGroups(groupId: groupId, pageIndex: 1, pageSize: 50);
    _updateReady((r) => r.copyWith(availableSubGroups: result.fold((_) => const [], (p) => p.items)));
  }

  void selectSubGroup(int subGroupId) => _updateReady((r) => r.copyWith(subGroupId: subGroupId));

  Future<int?> addSubGroupInline(String name) async {
    final current = state;
    if (current is! PersonWizardReady || current.groupId == null) return null;
    final result = await _subGroupRepository.createSubGroup(groupId: current.groupId!, name: name);
    return result.fold((failure) => null, (subGroup) {
      _dataRefreshBus.notify(DataScope.classification);
      _updateReady((r) => r.copyWith(
            availableSubGroups: [...r.availableSubGroups, subGroup],
            subGroupId: subGroup.id,
            didInlineAddClassification: true,
          ));
      return subGroup.id;
    });
  }

  Future<void> selectGovernorate(int governorateId) async {
    _updateReady((r) => r.copyWith(governorateId: governorateId, clearCity: true, clearNeighborhood: true));
    final result = await _cityRepository.getCities(governorateId: governorateId, pageIndex: 1, pageSize: 50);
    _updateReady((r) => r.copyWith(availableCities: result.fold((_) => const [], (p) => p.items)));
  }

  Future<int?> addGovernorateInline(String name) async {
    final result = await _governorateRepository.createGovernorate(name: name);
    return result.fold((failure) => null, (governorate) {
      _dataRefreshBus.notify(DataScope.classification);
      _updateReady((r) => r.copyWith(
            availableGovernorates: [...r.availableGovernorates, governorate],
            governorateId: governorate.id,
            clearCity: true,
            clearNeighborhood: true,
            didInlineAddClassification: true,
          ));
      return governorate.id;
    });
  }

  Future<void> selectCity(int cityId) async {
    _updateReady((r) => r.copyWith(cityId: cityId, clearNeighborhood: true));
    final result = await _neighborhoodRepository.getNeighborhoods(cityId: cityId, pageIndex: 1, pageSize: 50);
    _updateReady((r) => r.copyWith(availableNeighborhoods: result.fold((_) => const [], (p) => p.items)));
  }

  Future<int?> addCityInline(String name) async {
    final current = state;
    if (current is! PersonWizardReady || current.governorateId == null) return null;
    final result = await _cityRepository.createCity(governorateId: current.governorateId!, name: name);
    return result.fold((failure) => null, (city) {
      _dataRefreshBus.notify(DataScope.classification);
      _updateReady((r) => r.copyWith(
            availableCities: [...r.availableCities, city],
            cityId: city.id,
            clearNeighborhood: true,
            didInlineAddClassification: true,
          ));
      return city.id;
    });
  }

  void selectNeighborhood(int neighborhoodId) => _updateReady((r) => r.copyWith(neighborhoodId: neighborhoodId));

  Future<int?> addNeighborhoodInline(String name) async {
    final current = state;
    if (current is! PersonWizardReady || current.cityId == null) return null;
    final result = await _neighborhoodRepository.createNeighborhood(cityId: current.cityId!, name: name);
    return result.fold((failure) => null, (neighborhood) {
      _dataRefreshBus.notify(DataScope.classification);
      _updateReady((r) => r.copyWith(
            availableNeighborhoods: [...r.availableNeighborhoods, neighborhood],
            neighborhoodId: neighborhood.id,
            didInlineAddClassification: true,
          ));
      return neighborhood.id;
    });
  }

  // ---- Step 3 — Family & Relationships ----

  void addRelationshipRow() => _updateReady(
        (r) => r.copyWith(relationshipRows: [...r.relationshipRows, DraftRelationshipRow(localId: _newLocalId())]),
      );

  void removeRelationshipRow(String localId) => _updateReady(
        (r) => r.copyWith(relationshipRows: r.relationshipRows.where((row) => row.localId != localId).toList()),
      );

  void updateRelationshipType(String localId, RelationType type) => _updateReady(
        (r) => r.copyWith(
          relationshipRows: r.relationshipRows
              .map((row) => row.localId == localId ? row.copyWith(relationType: type) : row)
              .toList(),
        ),
      );

  void updateRelationshipPerson(String localId, int personId, String personName) => _updateReady(
        (r) => r.copyWith(
          relationshipRows: r.relationshipRows
              .map((row) => row.localId == localId
                  ? row.copyWith(relatedPersonId: personId, relatedPersonName: personName)
                  : row)
              .toList(),
        ),
      );

  // ---- Step 4 — Notes ----

  void updateNotes(String value) => _updateReady((r) => r.copyWith(notes: value));

  // ---- Submit ----

  Future<void> submit() async {
    final current = state;
    if (current is! PersonWizardReady) return;
    emit(current.copyWith(isSubmitting: true, clearSubmitError: true));

    final personResult = current.isEditing
        ? await _personRepository.updatePerson(
            id: current.personId!,
            name: current.name.trim(),
            phoneNumber: current.phoneNumber.trim().isEmpty ? null : current.phoneNumber.trim(),
            phoneNumber2: current.phoneNumber2.trim().isEmpty ? null : current.phoneNumber2.trim(),
            gender: current.gender!,
            groupId: current.groupId!,
            subGroupId: current.subGroupId,
            governorateId: current.governorateId!,
            cityId: current.cityId,
            neighborhoodId: current.neighborhoodId,
            notes: current.notes.trim().isEmpty ? null : current.notes.trim(),
          )
        : await _personRepository.createPerson(
            name: current.name.trim(),
            phoneNumber: current.phoneNumber.trim().isEmpty ? null : current.phoneNumber.trim(),
            phoneNumber2: current.phoneNumber2.trim().isEmpty ? null : current.phoneNumber2.trim(),
            gender: current.gender!,
            groupId: current.groupId!,
            subGroupId: current.subGroupId,
            governorateId: current.governorateId!,
            cityId: current.cityId,
            neighborhoodId: current.neighborhoodId,
            notes: current.notes.trim().isEmpty ? null : current.notes.trim(),
          );

    final personId = personResult.fold((failure) => null, (person) => person.id);
    if (personId == null) {
      final message = personResult.fold((f) => core.failureToMessage(f), (_) => '');
      emit(current.copyWith(isSubmitting: false, submitError: message));
      return;
    }

    final failures = <String>[
      ...await _syncPhotos(current, personId),
      ...await _syncRelationships(current, personId),
    ];

    _dataRefreshBus.notify(DataScope.people);
    if (current.didInlineAddClassification) {
      _dataRefreshBus.notify(DataScope.classification);
    }

    emit(PersonWizardSubmitSuccess(
      personId: personId,
      personName: current.name.trim(),
      partialFailureKeys: failures.isEmpty ? null : failures,
    ));
  }

  Future<List<String>> _syncPhotos(PersonWizardReady draft, int personId) async {
    final failures = <String>[];
    final currentExistingIds =
        draft.stagedPhotos.where((p) => p.existingImageId != null).map((p) => p.existingImageId!).toSet();

    for (final removedId in draft.originalPhotoIds.difference(currentExistingIds)) {
      final result = await _personImageRepository.deleteImage(personId: personId, imageId: removedId);
      result.fold((_) => failures.add('people.wizard.submit.photoRemoveFailed'), (_) {});
    }

    final uploadedIdByLocalId = <String, int>{};
    for (final photo in draft.stagedPhotos.where((p) => p.localFile != null)) {
      final result = await _personImageRepository.uploadImage(personId: personId, file: photo.localFile!);
      result.fold(
        (_) => failures.add('people.wizard.submit.photoUploadFailed'),
        (image) => uploadedIdByLocalId[photo.localId] = image.id,
      );
    }

    StagedPersonPhoto? primaryPhoto;
    for (final photo in draft.stagedPhotos) {
      if (photo.isPrimary) {
        primaryPhoto = photo;
        break;
      }
    }
    if (primaryPhoto != null) {
      final resolvedId = primaryPhoto.existingImageId ?? uploadedIdByLocalId[primaryPhoto.localId];
      if (resolvedId != null) {
        final result = await _personImageRepository.setPrimary(personId: personId, imageId: resolvedId);
        result.fold((_) => failures.add('people.wizard.submit.photoPrimaryFailed'), (_) {});
      }
    }

    return failures;
  }

  Future<List<String>> _syncRelationships(PersonWizardReady draft, int personId) async {
    final failures = <String>[];

    for (final row in draft.relationshipRows) {
      if (!row.isComplete) continue;
      if (row.existingRelationshipId == null || row.isEdited) {
        final result = await _personRelationshipRepository.createRelationship(
          personId: personId,
          relatedPersonId: row.relatedPersonId!,
          relationType: row.relationType!,
        );
        result.fold((_) => failures.add('people.wizard.submit.relationshipSaveFailed'), (_) {});
      }
    }

    final currentExistingIds =
        draft.relationshipRows.where((r) => r.existingRelationshipId != null).map((r) => r.existingRelationshipId!).toSet();
    final idsToDelete = <int>{
      ...draft.originalRelationshipIds.difference(currentExistingIds),
      ...draft.relationshipRows.where((r) => r.isEdited).map((r) => r.existingRelationshipId!),
    };

    for (final id in idsToDelete) {
      final result = await _personRelationshipRepository.deleteRelationship(personId: personId, relationshipId: id);
      result.fold((_) => failures.add('people.wizard.submit.relationshipRemoveFailed'), (_) {});
    }

    return failures;
  }

  void _updateReady(PersonWizardReady Function(PersonWizardReady) update) {
    final current = state;
    if (current is! PersonWizardReady) return;
    emit(update(current));
  }
}
