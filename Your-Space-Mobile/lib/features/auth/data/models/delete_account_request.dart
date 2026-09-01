class DeleteAccountRequest {
  final String password;

  const DeleteAccountRequest({required this.password});

  Map<String, dynamic> toJson() => {
        'password': password,
      };
}
