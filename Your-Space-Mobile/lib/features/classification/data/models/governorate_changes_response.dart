import 'governorate_response.dart';

/// `GovernorateChangesDto`'s shape (design doc §6, row 8.5/8.6): a page of
/// everything that changed since [cursor] was last seen — upserts and
/// tombstones together, ordered by the backend's `SyncVersion`. [upserts]
/// items reuse [GovernorateResponse] as-is (same row shape as
/// `GovernorateProfileDto`, and it already tolerates unknown/extra keys) —
/// no parallel model needed.
class GovernorateChangesResponse {
  final List<GovernorateResponse> upserts;
  final List<int> tombstoneIds;
  final int cursor;
  final bool hasMore;

  const GovernorateChangesResponse({
    required this.upserts,
    required this.tombstoneIds,
    required this.cursor,
    required this.hasMore,
  });

  factory GovernorateChangesResponse.fromJson(Map<String, dynamic> json) => GovernorateChangesResponse(
        upserts: (json['upserts'] as List<dynamic>)
            .map((e) => GovernorateResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
        tombstoneIds: (json['tombstoneIds'] as List<dynamic>).map((e) => e as int).toList(),
        cursor: json['cursor'] as int,
        hasMore: json['hasMore'] as bool,
      );
}
