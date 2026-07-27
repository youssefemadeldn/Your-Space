/// Unwraps the backend's `ServiceResult<T>` envelope:
/// `{ success, message, errorCode, data, statusCode, timestamp, errors }`.
///
/// For void endpoints (logout, delete) where `data` is null by design, bypass
/// this entirely: `fromJson: (_) => unit`.
T unwrapServiceResult<T>(
  Object? json,
  T Function(Object? inner) fromJson,
) {
  if (json is! Map<String, dynamic>) {
    throw const FormatException('Expected a JSON object envelope from the API.');
  }

  final data = json['data'];
  if (data == null) {
    throw const FormatException(
      'Envelope "data" was null — use fromJson: (_) => unit for void endpoints instead.',
    );
  }

  return fromJson(data);
}
