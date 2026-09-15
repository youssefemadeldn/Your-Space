import 'event_response.dart';

/// `EventChangesDto`'s shape (design doc §6, row 9.5/9.6): a page of
/// everything that changed since [cursor] was last seen — upserts and
/// tombstones together, ordered by the backend's `SyncVersion`. [upserts]
/// items reuse [EventResponse] as-is (same row shape as `EventProfileDto`,
/// and it already tolerates unknown/extra keys) — no parallel model needed.
class EventChangesResponse {
  final List<EventResponse> upserts;
  final List<int> tombstoneIds;
  final int cursor;
  final bool hasMore;

  const EventChangesResponse({
    required this.upserts,
    required this.tombstoneIds,
    required this.cursor,
    required this.hasMore,
  });

  factory EventChangesResponse.fromJson(Map<String, dynamic> json) => EventChangesResponse(
        upserts: (json['upserts'] as List<dynamic>)
            .map((e) => EventResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
        tombstoneIds: (json['tombstoneIds'] as List<dynamic>).map((e) => e as int).toList(),
        cursor: json['cursor'] as int,
        hasMore: json['hasMore'] as bool,
      );
}
