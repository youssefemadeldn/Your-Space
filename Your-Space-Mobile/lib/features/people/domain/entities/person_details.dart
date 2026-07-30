import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/entities/person.dart';

import 'person_occasion_history_entry.dart';

/// Pairs `Person` with the occasion history `PersonDetailsDto` embeds
/// unpaginated. Returned only by `PersonRepository.getPersonById` —
/// `PersonDetailsCubit`/`PersonFormCubit` destructure [person]/
/// [occasionHistory] into their own state shape at the call site, so this
/// type never needs to cross further into presentation itself.
class PersonDetails extends Equatable {
  final Person person;
  final List<PersonOccasionHistoryEntry> occasionHistory;
  final DateTime createdAt;

  const PersonDetails({required this.person, required this.occasionHistory, required this.createdAt});

  @override
  List<Object?> get props => [person, occasionHistory, createdAt];
}
