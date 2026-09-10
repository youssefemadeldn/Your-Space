// Id/GroupId come from the route (groups/{groupId}/subgroups/{id}), not the body.
class UpdateSubGroupRequest {
  final String name;
  final String? nameAr;

  const UpdateSubGroupRequest({required this.name, this.nameAr});

  Map<String, dynamic> toJson() => {
        'name': name,
        if (nameAr != null) 'nameAr': nameAr,
      };
}
