import 'neighborhood_response.dart';

/// `NeighborhoodChangesDto`'s shape (design doc §6, row 8.23/8.24): a page of
/// everything that changed since [cursor] was last seen — upserts and
/// tombstones together, ordered by the backend's `SyncVersion`. [upserts]
/// items reuse [NeighborhoodResponse] as-is (same row shape as
/// `NeighborhoodProfileDto`, and it already tolerates unknown/extra keys) —
/// no parallel model needed.
class NeighborhoodChangesResponse {
  final List<NeighborhoodResponse> upserts;
  final List<int> tombstoneIds;
  final int cursor;
  final bool hasMore;

  const NeighborhoodChangesResponse({
    required this.upserts,
    required this.tombstoneIds,
    required this.cursor,
    required this.hasMore,
  });

  factory NeighborhoodChangesResponse.fromJson(Map<String, dynamic> json) => NeighborhoodChangesResponse(
        upserts: (json['upserts'] as List<dynamic>)
            .map((e) => NeighborhoodResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
        tombstoneIds: (json['tombstoneIds'] as List<dynamic>).map((e) => e as int).toList(),
        cursor: json['cursor'] as int,
        hasMore: json['hasMore'] as bool,
      );
}
