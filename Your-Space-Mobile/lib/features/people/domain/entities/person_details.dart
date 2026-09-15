import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/entities/person_relationship.dart';

import 'person_occasion_history_entry.dart';

/// Pairs `Person` with the occasion history and relationships
/// `PersonDetailsDto` embeds unpaginated. Returned only by
/// `PersonRepository.getPersonById` — `PersonDetailsCubit`/`PersonWizardCubit`
/// destructure [person]/[occasionHistory]/[relationships] into their own
/// state shape at the call site, so this type never needs to cross further
/// into presentation itself.
///
/// [createdAt] is nullable because the offline fallback in
/// `PersonRepositoryImpl.getPersonById` (no cached value exists locally)
/// can't supply one — no current caller reads this field.
class PersonDetails extends Equatable {
  final Person person;
  final List<PersonOccasionHistoryEntry> occasionHistory;
  final List<PersonRelationship> relationships;
  final DateTime? createdAt;

  const PersonDetails({
    required this.person,
    required this.occasionHistory,
    required this.relationships,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [person, occasionHistory, relationships, createdAt];
}
