class ConfirmEmailRequest {
  final String email;
  final String code;

  const ConfirmEmailRequest({required this.email, required this.code});

  Map<String, dynamic> toJson() => {
        'email': email,
        'code': code,
      };
}
