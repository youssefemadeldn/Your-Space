class CreateEventRequest {
  final String name;
  final String? nameAr;
  final DateTime? eventDate;
  final String? notes;

  const CreateEventRequest({required this.name, this.nameAr, this.eventDate, this.notes});

  Map<String, dynamic> toJson() => {
        'name': name,
        if (nameAr != null) 'nameAr': nameAr,
        if (eventDate != null) 'eventDate': eventDate!.toIso8601String(),
        if (notes != null) 'notes': notes,
      };
}
