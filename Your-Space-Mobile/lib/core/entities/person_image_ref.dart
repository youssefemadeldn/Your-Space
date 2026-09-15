import 'package:equatable/equatable.dart';

/// A lightweight, bookkeeping-only reference to a person's photo — deliberately
/// distinct from [PersonImage] (which carries a live, presigned, renderable
/// `url`). Backs the local-first cache (row 9.15) that tracks *what images
/// exist* and *which is primary*, never anything renderable — a presigned
/// URL expires within minutes/hours and must never be cached as if stable.
/// Actually displaying an image still resolves a live URL via the existing
/// network-only `getImages` call, unchanged by this row.
class PersonImageRef extends Equatable {
  final int id;
  final int personId;
  final String objectKey;
  final bool isPrimary;

  const PersonImageRef({
    required this.id,
    required this.personId,
    required this.objectKey,
    required this.isPrimary,
  });

  @override
  List<Object?> get props => [id, personId, objectKey, isPrimary];
}
