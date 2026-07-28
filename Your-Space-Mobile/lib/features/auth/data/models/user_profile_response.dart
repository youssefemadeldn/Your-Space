import '../../domain/entities/user_profile.dart';

class UserProfileResponse {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final List<String> roles;

  const UserProfileResponse({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.roles,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) => UserProfileResponse(
        id: json['id'] as String,
        email: json['email'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        phoneNumber: json['phoneNumber'] as String?,
        roles: (json['roles'] as List<dynamic>).map((role) => role as String).toList(),
      );

  UserProfile toEntity() => UserProfile(
        id: id,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        roles: roles,
      );
}
