import 'subgroup_response.dart';

/// `SubGroupChangesDto`'s shape (design doc §6, row 8.17/8.18): a page of
/// everything that changed since [cursor] was last seen — upserts and
/// tombstones together, ordered by the backend's `SyncVersion`. [upserts]
/// items reuse [SubGroupResponse] as-is (same row shape as `SubGroupProfileDto`,
/// and it already tolerates unknown/extra keys) — no parallel model needed.
class SubGroupChangesResponse {
  final List<SubGroupResponse> upserts;
  final List<int> tombstoneIds;
  final int cursor;
  final bool hasMore;

  const SubGroupChangesResponse({
    required this.upserts,
    required this.tombstoneIds,
    required this.cursor,
    required this.hasMore,
  });

  factory SubGroupChangesResponse.fromJson(Map<String, dynamic> json) => SubGroupChangesResponse(
        upserts: (json['upserts'] as List<dynamic>)
            .map((e) => SubGroupResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
        tombstoneIds: (json['tombstoneIds'] as List<dynamic>).map((e) => e as int).toList(),
        cursor: json['cursor'] as int,
        hasMore: json['hasMore'] as bool,
      );
}
