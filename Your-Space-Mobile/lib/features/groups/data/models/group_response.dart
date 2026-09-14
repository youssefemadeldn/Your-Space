import 'package:your_space_mobile/core/entities/group.dart';

class GroupResponse {
  final int id;
  final String name;
  final String? nameAr;
  final DateTime? updatedAt;

  const GroupResponse({required this.id, required this.name, this.nameAr, this.updatedAt});

  factory GroupResponse.fromJson(Map<String, dynamic> json) => GroupResponse(
        id: json['id'] as int,
        name: json['name'] as String,
        nameAr: json['nameAr'] as String?,
        updatedAt: json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt'] as String),
      );

  Group toEntity() => Group(id: id, name: name, nameAr: nameAr, updatedAt: updatedAt);
}
