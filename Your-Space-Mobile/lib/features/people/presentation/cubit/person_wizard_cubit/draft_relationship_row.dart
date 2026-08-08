import 'package:your_space_mobile/core/entities/relation_type.dart';

/// One row of the wizard's Step 3 relationship repeater. [originalRelationType]/
/// [originalRelatedPersonId] are only set for a row pre-loaded in Edit mode —
/// they let `PersonWizardCubit.submit()` detect an in-place edit (changed
/// type or person on an existing row) and apply it as delete-old +
/// create-new, per the locked "simplest correct approach" diff strategy.
class DraftRelationshipRow {
  final String localId;
  final RelationType? relationType;
  final int? relatedPersonId;
  final String? relatedPersonName;
  final int? existingRelationshipId;
  final RelationType? originalRelationType;
  final int? originalRelatedPersonId;

  const DraftRelationshipRow({
    required this.localId,
    this.relationType,
    this.relatedPersonId,
    this.relatedPersonName,
    this.existingRelationshipId,
    this.originalRelationType,
    this.originalRelatedPersonId,
  });

  bool get isComplete => relationType != null && relatedPersonId != null;

  bool get isEdited =>
      existingRelationshipId != null &&
      (relationType != originalRelationType || relatedPersonId != originalRelatedPersonId);

  DraftRelationshipRow copyWith({
    RelationType? relationType,
    int? relatedPersonId,
    String? relatedPersonName,
  }) =>
      DraftRelationshipRow(
        localId: localId,
        relationType: relationType ?? this.relationType,
        relatedPersonId: relatedPersonId ?? this.relatedPersonId,
        relatedPersonName: relatedPersonName ?? this.relatedPersonName,
        existingRelationshipId: existingRelationshipId,
        originalRelationType: originalRelationType,
        originalRelatedPersonId: originalRelatedPersonId,
      );
}
