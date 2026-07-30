class UpdatePersonRequest {
  final int id;
  final String name;
  final String? phoneNumber;
  final int groupId;

  const UpdatePersonRequest({
    required this.id,
    required this.name,
    this.phoneNumber,
    required this.groupId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        'groupId': groupId,
      };
}
