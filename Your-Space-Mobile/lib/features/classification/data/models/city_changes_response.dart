import 'city_response.dart';

/// `CityChangesDto`'s shape (design doc §6, row 8.11/8.12): a page of
/// everything that changed since [cursor] was last seen — upserts and
/// tombstones together, ordered by the backend's `SyncVersion`. [upserts]
/// items reuse [CityResponse] as-is (same row shape as `CityProfileDto`, and
/// it already tolerates unknown/extra keys) — no parallel model needed.
class CityChangesResponse {
  final List<CityResponse> upserts;
  final List<int> tombstoneIds;
  final int cursor;
  final bool hasMore;

  const CityChangesResponse({
    required this.upserts,
    required this.tombstoneIds,
    required this.cursor,
    required this.hasMore,
  });

  factory CityChangesResponse.fromJson(Map<String, dynamic> json) => CityChangesResponse(
        upserts:
            (json['upserts'] as List<dynamic>).map((e) => CityResponse.fromJson(e as Map<String, dynamic>)).toList(),
        tombstoneIds: (json['tombstoneIds'] as List<dynamic>).map((e) => e as int).toList(),
        cursor: json['cursor'] as int,
        hasMore: json['hasMore'] as bool,
      );
}
