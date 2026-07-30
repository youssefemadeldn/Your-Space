class CreatePersonRequest {
  final String name;
  final String? phoneNumber;
  final int groupId;

  const CreatePersonRequest({required this.name, this.phoneNumber, required this.groupId});

  Map<String, dynamic> toJson() => {
        'name': name,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        'groupId': groupId,
      };
}
