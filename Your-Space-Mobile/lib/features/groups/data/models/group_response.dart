import 'package:your_space_mobile/core/entities/group.dart';

class GroupResponse {
  final int id;
  final String name;
  final String? nameAr;

  const GroupResponse({required this.id, required this.name, this.nameAr});

  factory GroupResponse.fromJson(Map<String, dynamic> json) => GroupResponse(
        id: json['id'] as int,
        name: json['name'] as String,
        nameAr: json['nameAr'] as String?,
      );

  Group toEntity() => Group(id: id, name: name, nameAr: nameAr);
}
