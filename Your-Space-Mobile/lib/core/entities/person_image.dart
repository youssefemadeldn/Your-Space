import 'package:equatable/equatable.dart';

/// One photo attached to a Person — mirrors `PersonImageDto`. Lives in core
/// alongside `Person`/`PersonRelationship` (consumed by the people feature's
/// wizard and, once primary, threaded into `Person.primaryPhotoUrl`).
class PersonImage extends Equatable {
  final int id;
  final String url;
  final bool isPrimary;

  const PersonImage({required this.id, required this.url, required this.isPrimary});

  @override
  List<Object?> get props => [id, url, isPrimary];
}
