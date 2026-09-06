import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/entities/city.dart';
import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/governorate.dart';
import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/entities/neighborhood.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/entities/subgroup.dart';

import 'draft_relationship_row.dart';
import 'staged_person_photo.dart';

sealed class PersonWizardState extends Equatable {
  const PersonWizardState();
  @override
  List<Object?> get props => const [];
}

final class PersonWizardInitial extends PersonWizardState {
  const PersonWizardInitial();
}

final class PersonWizardLoading extends PersonWizardState {
  const PersonWizardLoading();
}

final class PersonWizardReady extends PersonWizardState {
  // Identity
  final int? personId;

  // Step 1 — Basic Identity
  final String name;
  final String phoneNumber;
  final String phoneNumber2;
  final Gender? gender;
  final List<StagedPersonPhoto> stagedPhotos;

  // Step 2 — Classification & Location
  final int? groupId;
  final int? subGroupId;
  final int? governorateId;
  final int? cityId;
  final int? neighborhoodId;
  final List<Group> availableGroups;
  final List<SubGroup> availableSubGroups;
  final List<Governorate> availableGovernorates;
  final List<City> availableCities;
  final List<Neighborhood> availableNeighborhoods;

  // Step 3 — Family & Relationships
  final List<DraftRelationshipRow> relationshipRows;
  final List<Person> peopleForLookup;

  // Step 4 — Notes
  final String notes;

  // Submit
  final bool isSubmitting;
  final String? submitError;

  // Diff baselines (Edit mode only — empty in Add mode)
  final Set<int> originalPhotoIds;
  final Set<int> originalRelationshipIds;
  final bool didInlineAddClassification;

  bool get isEditing => personId != null;

  const PersonWizardReady({
    this.personId,
    this.name = '',
    this.phoneNumber = '',
    this.phoneNumber2 = '',
    this.gender,
    this.stagedPhotos = const [],
    this.groupId,
    this.subGroupId,
    this.governorateId,
    this.cityId,
    this.neighborhoodId,
    this.availableGroups = const [],
    this.availableSubGroups = const [],
    this.availableGovernorates = const [],
    this.availableCities = const [],
    this.availableNeighborhoods = const [],
    this.relationshipRows = const [],
    this.peopleForLookup = const [],
    this.notes = '',
    this.isSubmitting = false,
    this.submitError,
    this.originalPhotoIds = const {},
    this.originalRelationshipIds = const {},
    this.didInlineAddClassification = false,
  });

  PersonWizardReady copyWith({
    String? name,
    String? phoneNumber,
    String? phoneNumber2,
    Gender? gender,
    List<StagedPersonPhoto>? stagedPhotos,
    int? groupId,
    bool clearSubGroup = false,
    int? subGroupId,
    int? governorateId,
    bool clearCity = false,
    int? cityId,
    bool clearNeighborhood = false,
    int? neighborhoodId,
    List<Group>? availableGroups,
    List<SubGroup>? availableSubGroups,
    List<Governorate>? availableGovernorates,
    List<City>? availableCities,
    List<Neighborhood>? availableNeighborhoods,
    List<DraftRelationshipRow>? relationshipRows,
    List<Person>? peopleForLookup,
    String? notes,
    bool? isSubmitting,
    String? submitError,
    bool clearSubmitError = false,
    bool? didInlineAddClassification,
  }) =>
      PersonWizardReady(
        personId: personId,
        name: name ?? this.name,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        phoneNumber2: phoneNumber2 ?? this.phoneNumber2,
        gender: gender ?? this.gender,
        stagedPhotos: stagedPhotos ?? this.stagedPhotos,
        groupId: groupId ?? this.groupId,
        subGroupId: clearSubGroup ? null : (subGroupId ?? this.subGroupId),
        governorateId: governorateId ?? this.governorateId,
        cityId: clearCity ? null : (cityId ?? this.cityId),
        neighborhoodId: clearNeighborhood ? null : (neighborhoodId ?? this.neighborhoodId),
        availableGroups: availableGroups ?? this.availableGroups,
        availableSubGroups: availableSubGroups ?? (clearSubGroup ? const [] : this.availableSubGroups),
        availableGovernorates: availableGovernorates ?? this.availableGovernorates,
        availableCities: availableCities ?? (clearCity ? const [] : this.availableCities),
        availableNeighborhoods:
            availableNeighborhoods ?? (clearNeighborhood ? const [] : this.availableNeighborhoods),
        relationshipRows: relationshipRows ?? this.relationshipRows,
        peopleForLookup: peopleForLookup ?? this.peopleForLookup,
        notes: notes ?? this.notes,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        submitError: clearSubmitError ? null : (submitError ?? this.submitError),
        originalPhotoIds: originalPhotoIds,
        originalRelationshipIds: originalRelationshipIds,
        didInlineAddClassification: didInlineAddClassification ?? this.didInlineAddClassification,
      );

  @override
  List<Object?> get props => [
        personId,
        name,
        phoneNumber,
        phoneNumber2,
        gender,
        stagedPhotos,
        groupId,
        subGroupId,
        governorateId,
        cityId,
        neighborhoodId,
        availableGroups,
        availableSubGroups,
        availableGovernorates,
        availableCities,
        availableNeighborhoods,
        relationshipRows,
        peopleForLookup,
        notes,
        isSubmitting,
        submitError,
      ];
}

final class PersonWizardSubmitSuccess extends PersonWizardState {
  final int personId;
  final String personName;

  /// Translation keys for any non-fatal photo/relationship sync failures —
  /// kept as raw keys (not a pre-joined display string) so the screen can
  /// `.tr()` each one individually rather than calling `.tr()` once on an
  /// already-joined multi-key string, which wouldn't resolve.
  final List<String>? partialFailureKeys;

  const PersonWizardSubmitSuccess({
    required this.personId,
    required this.personName,
    this.partialFailureKeys,
  });

  @override
  List<Object?> get props => [personId, personName, partialFailureKeys];
}

final class PersonWizardError extends PersonWizardState {
  final String message;
  const PersonWizardError(this.message);
  @override
  List<Object?> get props => [message];
}
