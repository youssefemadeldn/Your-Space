class CreateGroupRequest {
  final String name;
  final String? nameAr;

  const CreateGroupRequest({required this.name, this.nameAr});

  Map<String, dynamic> toJson() => {
        'name': name,
        if (nameAr != null) 'nameAr': nameAr,
      };
}
