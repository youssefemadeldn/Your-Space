class ResendConfirmationEmailRequest {
  final String email;

  const ResendConfirmationEmailRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}
