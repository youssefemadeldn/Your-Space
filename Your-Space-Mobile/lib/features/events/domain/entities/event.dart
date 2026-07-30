import 'package:equatable/equatable.dart';

class Event extends Equatable {
  final int id;
  final String name;
  final String? nameAr;
  final DateTime? eventDate;
  final String? notes;
  final int totalGuestCount;

  const Event({
    required this.id,
    required this.name,
    this.nameAr,
    this.eventDate,
    this.notes,
    this.totalGuestCount = 0,
  });

  @override
  List<Object?> get props => [id, name, nameAr, eventDate, notes, totalGuestCount];
}
