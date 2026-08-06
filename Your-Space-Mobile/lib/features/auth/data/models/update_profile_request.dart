class UpdateProfileRequest {
  final String firstName;
  final String lastName;
  final String phoneNumber;

  const UpdateProfileRequest({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
      };
}
