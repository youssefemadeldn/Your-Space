import 'person_response.dart';

/// `PersonChangesDto`'s shape (design doc §6, row 6): a page of everything
/// that changed since [cursor] was last seen — upserts and tombstones
/// together, ordered by the backend's `SyncVersion`. [upserts] items reuse
/// [PersonResponse] as-is (same row shape as `PersonProfileDto`, and it
/// already tolerates unknown/extra keys) — no parallel model needed.
class PersonChangesResponse {
  final List<PersonResponse> upserts;
  final List<int> tombstoneIds;
  final int cursor;
  final bool hasMore;

  const PersonChangesResponse({
    required this.upserts,
    required this.tombstoneIds,
    required this.cursor,
    required this.hasMore,
  });

  factory PersonChangesResponse.fromJson(Map<String, dynamic> json) => PersonChangesResponse(
        upserts: (json['upserts'] as List<dynamic>)
            .map((e) => PersonResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
        tombstoneIds: (json['tombstoneIds'] as List<dynamic>).map((e) => e as int).toList(),
        cursor: json['cursor'] as int,
        hasMore: json['hasMore'] as bool,
      );
}
