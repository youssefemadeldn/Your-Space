import 'package:your_space_mobile/features/events/domain/entities/event.dart';

/// Parses `EventProfileDto`'s fields. Also reused for get-by-id/create/update
/// responses (`EventDetailsDto`, a superset) — extra keys (the guest-status
/// counts beyond `totalGuestCount`, `createdAt`) are simply ignored since this
/// only reads the keys below. `nameAr` is never present on either DTO shape.
class EventResponse {
  final int id;
  final String name;
  final String? nameAr;
  final DateTime? eventDate;
  final String? notes;
  final int totalGuestCount;

  const EventResponse({
    required this.id,
    required this.name,
    this.nameAr,
    this.eventDate,
    this.notes,
    required this.totalGuestCount,
  });

  factory EventResponse.fromJson(Map<String, dynamic> json) => EventResponse(
        id: json['id'] as int,
        name: json['name'] as String,
        nameAr: json['nameAr'] as String?,
        eventDate: json['eventDate'] == null ? null : DateTime.parse(json['eventDate'] as String),
        notes: json['notes'] as String?,
        totalGuestCount: json['totalGuestCount'] as int,
      );

  Event toEntity() => Event(
        id: id,
        name: name,
        nameAr: nameAr,
        eventDate: eventDate,
        notes: notes,
        totalGuestCount: totalGuestCount,
      );
}
