import '../../domain/entities/user_profile.dart';
import 'user_profile_response.dart';

class AuthResponse {
  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final UserProfileResponse user;

  const AuthResponse({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['accessToken'] as String,
        accessTokenExpiresAt: DateTime.parse(json['accessTokenExpiresAt'] as String),
        refreshToken: json['refreshToken'] as String,
        user: UserProfileResponse.fromJson(json['user'] as Map<String, dynamic>),
      );

  UserProfile toEntity() => user.toEntity();
}
