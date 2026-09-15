import 'package:equatable/equatable.dart';

class Event extends Equatable {
  final int id;
  final String name;
  final String? nameAr;
  final DateTime? eventDate;
  final String? notes;
  final int totalGuestCount;

  // Tier 3 watermark field (row 9.6) — nullable until the row has been
  // round-tripped through the server at least once (a locally-created draft
  // has none yet).
  final DateTime? updatedAt;

  const Event({
    required this.id,
    required this.name,
    this.nameAr,
    this.eventDate,
    this.notes,
    this.totalGuestCount = 0,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [id, name, nameAr, eventDate, notes, totalGuestCount, updatedAt];
}
