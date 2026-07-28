class ResetPasswordRequest {
  final String email;
  final String code;
  final String newPassword;
  final String confirmNewPassword;

  const ResetPasswordRequest({
    required this.email,
    required this.code,
    required this.newPassword,
    required this.confirmNewPassword,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'code': code,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      };
}
