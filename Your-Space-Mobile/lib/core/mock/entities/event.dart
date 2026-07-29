import 'package:equatable/equatable.dart';

/// Mirrors `EventProfileDto` exactly — the list view only ever gets
/// [totalGuestCount], never a status breakdown (that's [EventGuestProgressSummary]).
class Event extends Equatable {
  final int id;
  final String name;
  final String? nameAr;
  final DateTime? eventDate;
  final String? notes;
  final int totalGuestCount;
  final DateTime createdAt;

  const Event({
    required this.id,
    required this.name,
    this.nameAr,
    this.eventDate,
    this.notes,
    this.totalGuestCount = 0,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, name, nameAr, eventDate, notes, totalGuestCount, createdAt];
}
