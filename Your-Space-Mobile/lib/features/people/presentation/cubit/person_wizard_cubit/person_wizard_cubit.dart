import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show UniqueKey;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/constants/app_constants.dart';
import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/person_image.dart';
import 'package:your_space_mobile/core/entities/relation_type.dart';
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

  /// Debounces the Step 3 person-lookup field — mirrors `PeopleListCubit`'s
  /// `_searchDebounce`. Cancelled in [close].
  Timer? _relationshipSearchDebounce;

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

    // Groups (row 7.2) and Governorates (row 8.2) are both local-first now —
    // a local read can't fail the way a network call can, so neither is part
    // of a prerequisite-failure check anymore.
    final groupsFuture = _groupRepository.watchGroups(limit: 50).first;
    final governoratesFuture = _governorateRepository.watchGovernorates(limit: 50).first;
    final detailsFuture = personId == null ? null : _personRepository.getPersonById(personId);

    final groups = await groupsFuture;
    final governorates = await governoratesFuture;

    if (personId == null) {
      emit(PersonWizardReady(
        availableGroups: groups,
        availableGovernorates: governorates,
      ));
      return;
    }

    final detailsResult = await detailsFuture!;
    await detailsResult.fold(
      (failure) async => emit(PersonWizardError(core.failureToMessage(failure))),
      (details) async {
        final person = details.person;

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
          notes: person.notes ?? '',
          facebookUrl: person.facebookUrl ?? '',
          originalPhotoIds: images.map((i) => i.id).toSet(),
          originalRelationshipIds: details.relationships.map((r) => r.id).toSet(),
        );

        // SubGroup is local-first (row 8.14) — a local read can't fail the
        // way a network call can.
        final subGroups = await _subGroupRepository.watchSubGroups(groupId: person.groupId, limit: 50).first;
        ready = ready.copyWith(availableSubGroups: subGroups);

        // City is local-first (row 8.8) — a local read can't fail the way a
        // network call can.
        final cities = await _cityRepository.watchCities(governorateId: person.governorateId, limit: 50).first;
        ready = ready.copyWith(availableCities: cities);

        if (person.cityId != null) {
          // Neighborhood is local-first (row 8.20) — a local read can't fail
          // the way a network call can.
          final neighborhoods =
              await _neighborhoodRepository.watchNeighborhoods(cityId: person.cityId!, limit: 50).first;
          ready = ready.copyWith(availableNeighborhoods: neighborhoods);
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
      case 2:
        // A row with exactly one of {relation type, person} filled is a
        // half-entered relationship that would be silently dropped at submit.
        final hasPartialRow = current.relationshipRows.any(
          (r) => (r.relationType != null) != (r.relatedPersonId != null),
        );
        if (hasPartialRow) return 'people.wizard.step3.incompleteRelationship';
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
    final subGroups = await _subGroupRepository.watchSubGroups(groupId: groupId, limit: 50).first;
    _updateReady((r) => r.copyWith(availableSubGroups: subGroups));
  }

  /// Inline "+ Add new group" from the Step 2 group picker — mirrors
  /// [addGovernorateInline]. Group is required, has no management screen
  /// reachable from the wizard, and a zero-group account would otherwise be
  /// stuck, so creating one here is the only way forward.
  Future<int?> addGroupInline(String name) async {
    // createGroupAndSync, not createGroup: the outbox (row 7.3) makes a
    // plain createGroup optimistic (a temp negative id), but this id gets
    // embedded directly into the in-progress person's own `groupId` — a
    // value that can never resolve to a real server id via Person's own
    // reconciliation, which only rewrites Person outbox rows keyed to a
    // Person tempId, not a foreign Group tempId sitting inside an
    // already-built Person payload. createGroupAndSync guarantees this
    // always returns either a real, server-confirmed id or null (on
    // failure, same as before this row).
    final result = await _groupRepository.createGroupAndSync(name: name);
    return result.fold((failure) => null, (group) {
      _dataRefreshBus.notify(DataScope.groups);
      _updateReady((r) => r.copyWith(
            availableGroups: [...r.availableGroups, group],
            groupId: group.id,
            clearSubGroup: true,
            availableSubGroups: const [],
          ));
      return group.id;
    });
  }

  void selectSubGroup(int subGroupId) => _updateReady((r) => r.copyWith(subGroupId: subGroupId));

  Future<int?> addSubGroupInline(String name) async {
    final current = state;
    if (current is! PersonWizardReady || current.groupId == null) return null;
    // createSubGroupAndSync, not createSubGroup: same reasoning as
    // addCityInline above — this id gets embedded directly into the
    // in-progress person's own `subGroupId`, a value SubGroup's own
    // reconciliation can't reach once it's sitting inside an already-built
    // Person payload.
    final result = await _subGroupRepository.createSubGroupAndSync(groupId: current.groupId!, name: name);
    return result.fold((failure) => null, (subGroup) {
      _updateReady((r) => r.copyWith(
            availableSubGroups: [...r.availableSubGroups, subGroup],
            subGroupId: subGroup.id,
          ));
      return subGroup.id;
    });
  }

  Future<void> selectGovernorate(int governorateId) async {
    _updateReady((r) => r.copyWith(governorateId: governorateId, clearCity: true, clearNeighborhood: true));
    // City is local-first (row 8.8) — a local read can't fail the way a
    // network call can.
    final cities = await _cityRepository.watchCities(governorateId: governorateId, limit: 50).first;
    _updateReady((r) => r.copyWith(availableCities: cities));
  }

  Future<int?> addGovernorateInline(String name) async {
    // createGovernorateAndSync, not createGovernorate: the outbox (row 8.3)
    // makes a plain createGovernorate optimistic (a temp negative id), but
    // this id gets embedded directly into the in-progress person's own
    // `governorateId` — a value that can never resolve to a real server id
    // via Person's own reconciliation, which only rewrites Person outbox
    // rows keyed to a Person tempId, not a foreign Governorate tempId
    // sitting inside an already-built Person payload.
    // createGovernorateAndSync guarantees this always returns either a
    // real, server-confirmed id or null (on failure, same as before this
    // row).
    final result = await _governorateRepository.createGovernorateAndSync(name: name);
    return result.fold((failure) => null, (governorate) {
      _updateReady((r) => r.copyWith(
            availableGovernorates: [...r.availableGovernorates, governorate],
            governorateId: governorate.id,
            clearCity: true,
            clearNeighborhood: true,
          ));
      return governorate.id;
    });
  }

  Future<void> selectCity(int cityId) async {
    _updateReady((r) => r.copyWith(cityId: cityId, clearNeighborhood: true));
    // Neighborhood is local-first (row 8.20) — a local read can't fail the
    // way a network call can.
    final neighborhoods = await _neighborhoodRepository.watchNeighborhoods(cityId: cityId, limit: 50).first;
    _updateReady((r) => r.copyWith(availableNeighborhoods: neighborhoods));
  }

  Future<int?> addCityInline(String name) async {
    final current = state;
    if (current is! PersonWizardReady || current.governorateId == null) return null;
    // createCityAndSync, not createCity: same reasoning as addGovernorateInline
    // above — this id gets embedded directly into the in-progress person's
    // own `cityId`, a value City's own reconciliation can't reach once it's
    // sitting inside an already-built Person payload.
    final result = await _cityRepository.createCityAndSync(governorateId: current.governorateId!, name: name);
    return result.fold((failure) => null, (city) {
      _updateReady((r) => r.copyWith(
            availableCities: [...r.availableCities, city],
            cityId: city.id,
            clearNeighborhood: true,
          ));
      return city.id;
    });
  }

  void selectNeighborhood(int neighborhoodId) => _updateReady((r) => r.copyWith(neighborhoodId: neighborhoodId));

  Future<int?> addNeighborhoodInline(String name) async {
    final current = state;
    if (current is! PersonWizardReady || current.cityId == null) return null;
    // createNeighborhoodAndSync, not createNeighborhood: same reasoning as
    // addCityInline above — this id gets embedded directly into the
    // in-progress person's own `neighborhoodId`, a value Neighborhood's own
    // reconciliation can't reach once it's sitting inside an already-built
    // Person payload.
    final result = await _neighborhoodRepository.createNeighborhoodAndSync(cityId: current.cityId!, name: name);
    return result.fold((failure) => null, (neighborhood) {
      _updateReady((r) => r.copyWith(
            availableNeighborhoods: [...r.availableNeighborhoods, neighborhood],
            neighborhoodId: neighborhood.id,
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

  /// Debounced local-first lookup for the focused relationship row's person
  /// field. Person is local-first (CLAUDE.md Architecture rule 7): the full
  /// owned dataset is cached on-device, so `watchPersons(search:, limit:)`
  /// searches the complete synced collection — not a capped page — and works
  /// offline. This superseded an earlier server-side search that itself had
  /// replaced an even older fixed 200-row client snapshot.
  void searchRelationshipPeople(String query) {
    _relationshipSearchDebounce?.cancel();
    _relationshipSearchDebounce =
        Timer(const Duration(milliseconds: 400), () => _runRelationshipSearch(query));
  }

  Future<void> _runRelationshipSearch(String query) async {
    final current = state;
    if (current is! PersonWizardReady) return;
    emit(current.copyWith(relationshipLookupLoading: true));

    final trimmed = query.trim();
    final people = await _personRepository
        .watchPersons(search: trimmed.isEmpty ? null : trimmed, limit: AppConstants.kDefaultPageSize)
        .first;
    if (isClosed) return;
    final latest = state;
    if (latest is! PersonWizardReady) return;

    // Edit mode: a person can't be related to itself.
    final filtered =
        latest.personId == null ? people : people.where((p) => p.id != latest.personId).toList();
    emit(latest.copyWith(relationshipLookupResults: filtered, relationshipLookupLoading: false));
  }

  /// Clears the shared lookup list — called when a row's field loses focus or
  /// a person is picked, so a stale result set never flashes under the next
  /// row the user focuses.
  void clearRelationshipLookup() {
    _relationshipSearchDebounce?.cancel();
    final current = state;
    if (current is! PersonWizardReady) return;
    if (current.relationshipLookupResults.isEmpty && !current.relationshipLookupLoading) return;
    emit(current.copyWith(relationshipLookupResults: const [], relationshipLookupLoading: false));
  }

  // ---- Step 4 — Notes ----

  void updateNotes(String value) => _updateReady((r) => r.copyWith(notes: value));
  void updateFacebookUrl(String value) => _updateReady((r) => r.copyWith(facebookUrl: value));

  // ---- Submit ----

  Future<void> submit() async {
    final current = state;
    if (current is! PersonWizardReady) return;
    emit(current.copyWith(isSubmitting: true, clearSubmitError: true));

    // Photo/relationship uploads need a real, resolved server id right
    // after create/update — they aren't part of the People Tier-1 pilot cut
    // (design doc §4) and stay network-only. A submission with no such
    // changes can go through the pure-optimistic outbox path instead
    // (Tier 2, design doc §5) and return without waiting on the network at
    // all, even offline.
    final needsSync = _hasPendingChildWrites(current);

    final groupName = current.availableGroups.firstWhere((g) => g.id == current.groupId).name;
    final subGroupName = current.subGroupId == null
        ? null
        : current.availableSubGroups.firstWhere((s) => s.id == current.subGroupId).name;
    final governorateName =
        current.availableGovernorates.firstWhere((g) => g.id == current.governorateId).name;
    final cityName =
        current.cityId == null ? null : current.availableCities.firstWhere((c) => c.id == current.cityId).name;
    final neighborhoodName = current.neighborhoodId == null
        ? null
        : current.availableNeighborhoods.firstWhere((n) => n.id == current.neighborhoodId).name;

    final personResult = current.isEditing
        // Always the AndSync variant on edit, regardless of needsSync: `id`
        // is always an already-real person, so there's no temp-id risk in
        // opportunistically syncing now when online — and it closes the
        // race where the Person Details screen's next network read would
        // otherwise show stale data until the next background sync trigger
        // (see updatePersonAndSync's doc comment for the offline fallback).
        ? await _personRepository.updatePersonAndSync(
            id: current.personId!,
            name: current.name.trim(),
            phoneNumber: current.phoneNumber.trim().isEmpty ? null : current.phoneNumber.trim(),
            phoneNumber2: current.phoneNumber2.trim().isEmpty ? null : current.phoneNumber2.trim(),
            gender: current.gender!,
            groupId: current.groupId!,
            groupName: groupName,
            subGroupId: current.subGroupId,
            subGroupName: subGroupName,
            governorateId: current.governorateId!,
            governorateName: governorateName,
            cityId: current.cityId,
            cityName: cityName,
            neighborhoodId: current.neighborhoodId,
            neighborhoodName: neighborhoodName,
            notes: current.notes.trim().isEmpty ? null : current.notes.trim(),
            facebookUrl: current.facebookUrl.trim().isEmpty ? null : current.facebookUrl.trim(),
          )
        : (needsSync
            ? await _personRepository.createPersonAndSync(
                name: current.name.trim(),
                phoneNumber: current.phoneNumber.trim().isEmpty ? null : current.phoneNumber.trim(),
                phoneNumber2: current.phoneNumber2.trim().isEmpty ? null : current.phoneNumber2.trim(),
                gender: current.gender!,
                groupId: current.groupId!,
                groupName: groupName,
                subGroupId: current.subGroupId,
                subGroupName: subGroupName,
                governorateId: current.governorateId!,
                governorateName: governorateName,
                cityId: current.cityId,
                cityName: cityName,
                neighborhoodId: current.neighborhoodId,
                neighborhoodName: neighborhoodName,
                notes: current.notes.trim().isEmpty ? null : current.notes.trim(),
                facebookUrl: current.facebookUrl.trim().isEmpty ? null : current.facebookUrl.trim(),
              )
            : await _personRepository.createPerson(
                name: current.name.trim(),
                phoneNumber: current.phoneNumber.trim().isEmpty ? null : current.phoneNumber.trim(),
                phoneNumber2: current.phoneNumber2.trim().isEmpty ? null : current.phoneNumber2.trim(),
                gender: current.gender!,
                groupId: current.groupId!,
                groupName: groupName,
                subGroupId: current.subGroupId,
                subGroupName: subGroupName,
                governorateId: current.governorateId!,
                governorateName: governorateName,
                cityId: current.cityId,
                cityName: cityName,
                neighborhoodId: current.neighborhoodId,
                neighborhoodName: neighborhoodName,
                notes: current.notes.trim().isEmpty ? null : current.notes.trim(),
                facebookUrl: current.facebookUrl.trim().isEmpty ? null : current.facebookUrl.trim(),
              ));

    if (isClosed) return;
    final personId = personResult.fold((failure) => null, (person) => person.id);
    if (personId == null) {
      final message = personResult.fold((f) => core.failureToMessage(f), (_) => '');
      emit(current.copyWith(isSubmitting: false, submitError: message));
      return;
    }

    if (!needsSync) {
      // Pure optimistic path: nothing else needs a real id, so there's
      // nothing left to await — this is the offline-create/edit UX Tier 2
      // unlocks (today this branch would have blocked on the network and
      // errored outright when offline).
      _dataRefreshBus.notify(DataScope.people);
      emit(PersonWizardSubmitSuccess(
        personId: personId,
        personName: current.name.trim(),
        partialFailureKeys: null,
      ));
      return;
    }

    final failures = <String>[
      ...await _syncPhotos(current, personId),
      ...await _syncRelationships(current, personId),
    ];

    if (isClosed) return;
    _dataRefreshBus.notify(DataScope.people);

    emit(PersonWizardSubmitSuccess(
      personId: personId,
      personName: current.name.trim(),
      partialFailureKeys: failures.isEmpty ? null : failures,
    ));
  }

  /// Mirrors the exact removal/upload/add detection `_syncPhotos`/
  /// `_syncRelationships` already do inline — extracted so `submit()` can
  /// decide, before calling the repository, whether this submission needs
  /// the network-synchronous path (design doc §5, decision 3).
  bool _hasPendingChildWrites(PersonWizardReady draft) {
    final currentExistingPhotoIds =
        draft.stagedPhotos.where((p) => p.existingImageId != null).map((p) => p.existingImageId!).toSet();
    final hasPhotoRemoval = draft.originalPhotoIds.difference(currentExistingPhotoIds).isNotEmpty;
    final hasPhotoUpload = draft.stagedPhotos.any((p) => p.localFile != null);

    final currentExistingRelationshipIds = draft.relationshipRows
        .where((r) => r.existingRelationshipId != null)
        .map((r) => r.existingRelationshipId!)
        .toSet();
    final hasRelationshipRemoval =
        draft.originalRelationshipIds.difference(currentExistingRelationshipIds).isNotEmpty;
    final hasRelationshipChange =
        draft.relationshipRows.any((r) => r.isComplete && (r.existingRelationshipId == null || r.isEdited));

    return hasPhotoRemoval || hasPhotoUpload || hasRelationshipRemoval || hasRelationshipChange;
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

  @override
  Future<void> close() {
    _relationshipSearchDebounce?.cancel();
    return super.close();
  }
}
