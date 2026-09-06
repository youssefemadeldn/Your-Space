import 'package:your_space_mobile/core/entities/person_image.dart';

class PersonImageResponse {
  final int id;
  final String url;
  final bool isPrimary;

  const PersonImageResponse({required this.id, required this.url, required this.isPrimary});

  factory PersonImageResponse.fromJson(Map<String, dynamic> json) => PersonImageResponse(
        id: json['id'] as int,
        url: json['url'] as String,
        isPrimary: json['isPrimary'] as bool,
      );

  PersonImage toEntity() => PersonImage(id: id, url: url, isPrimary: isPrimary);
}
