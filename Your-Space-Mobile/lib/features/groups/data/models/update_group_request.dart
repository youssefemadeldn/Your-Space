class UpdateGroupRequest {
  final int id;
  final String name;
  final String? nameAr;

  const UpdateGroupRequest({required this.id, required this.name, this.nameAr});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (nameAr != null) 'nameAr': nameAr,
      };
}
