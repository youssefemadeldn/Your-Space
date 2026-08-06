import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/core/entities/gender.dart';

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final Gender gender;
  final List<String> roles;

  const UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.gender,
    required this.roles,
  });

  @override
  List<Object?> get props => [id, email, firstName, lastName, phoneNumber, gender, roles];
}
