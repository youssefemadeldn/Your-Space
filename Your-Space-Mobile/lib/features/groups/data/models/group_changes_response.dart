import 'group_response.dart';

/// `GroupChangesDto`'s shape (design doc §6, row 7.5/7.6): a page of
/// everything that changed since [cursor] was last seen — upserts and
/// tombstones together, ordered by the backend's `SyncVersion`. [upserts]
/// items reuse [GroupResponse] as-is (same row shape as `GroupProfileDto`,
/// and it already tolerates unknown/extra keys) — no parallel model needed.
class GroupChangesResponse {
  final List<GroupResponse> upserts;
  final List<int> tombstoneIds;
  final int cursor;
  final bool hasMore;

  const GroupChangesResponse({
    required this.upserts,
    required this.tombstoneIds,
    required this.cursor,
    required this.hasMore,
  });

  factory GroupChangesResponse.fromJson(Map<String, dynamic> json) => GroupChangesResponse(
        upserts: (json['upserts'] as List<dynamic>)
            .map((e) => GroupResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
        tombstoneIds: (json['tombstoneIds'] as List<dynamic>).map((e) => e as int).toList(),
        cursor: json['cursor'] as int,
        hasMore: json['hasMore'] as bool,
      );
}
