import 'package:your_space_mobile/core/entities/person_image.dart';

class PersonImageResponse {
  final int id;
  final String url;
  final bool isPrimary;

  // Row 9.17 — present on the create/upload response so the outbox
  // replayer can populate the local bookkeeping cache without waiting for
  // the next Tier 3 pull. Never itself a display value — [url] stays the
  // only renderable field. Nullable because the nested list endpoint
  // (GetAll) doesn't guarantee it's always parsed the same way; defensively
  // tolerant of an absent key.
  final String? objectKey;

  const PersonImageResponse({required this.id, required this.url, required this.isPrimary, this.objectKey});

  factory PersonImageResponse.fromJson(Map<String, dynamic> json) => PersonImageResponse(
        id: json['id'] as int,
        url: json['url'] as String,
        isPrimary: json['isPrimary'] as bool,
        objectKey: json['objectKey'] as String?,
      );

  PersonImage toEntity() => PersonImage(id: id, url: url, isPrimary: isPrimary);
}
