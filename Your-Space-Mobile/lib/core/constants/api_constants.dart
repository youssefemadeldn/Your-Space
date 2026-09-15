class ApiConstants {
  ApiConstants._();

  static const String _devBaseUrl =
      'https://yourspace.booksplatform.net/api/v1';
  static const String _prodBaseUrl =
      'https://yourspace.booksplatform.net/api/v1';

  static String get baseUrl =>
      const String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev') == 'prod'
      ? _prodBaseUrl
      : _devBaseUrl;

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Used by AuthInterceptor itself — not a feature-layer concern.
  static const String refreshToken = '/auth/refresh-token';

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String confirmEmail = '/auth/confirm-email';
  static const String resendConfirmationEmail =
      '/auth/resend-confirmation-email';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String deleteAccount = '/auth/me';
  static const String profile = '/auth/me';
  static const String avatar = '/auth/me/avatar';

  // Base segments only — nested paths (e.g. '$events/$eventId/guests') are
  // interpolated at the datasource call site.
  static const String groups = '/groups';
  static const String persons = '/persons';
  static const String events = '/events';

  // Sprint 4 — Subgroup + Location hierarchy + Relationship engine. All
  // nested under their parent (e.g. '$groups/$groupId/$subgroupsSegment').
  static const String subgroupsSegment = 'subgroups';
  // Flat "all mine" endpoint (row 8.14) — separate from subgroupsSegment, which is always used
  // nested under a group ('$groups/$groupId/$subgroupsSegment').
  static const String subgroups = '/subgroups';
  static const String governorates = '/governorates';
  static const String citiesSegment = 'cities';
  // Flat "all mine" endpoint (row 8.8) — separate from citiesSegment, which is always used
  // nested under a governorate ('$governorates/$governorateId/$citiesSegment').
  static const String cities = '/cities';
  // Flat "all mine" endpoint (row 9.8), event-agnostic — separate from the nested guest routes
  // built at the EventGuest datasource call site ('$events/$eventId/guests').
  static const String eventGuests = '/event-guests';
  static const String neighborhoodsSegment = 'neighborhoods';
  // Flat "all mine" endpoint (row 8.20) — separate from neighborhoodsSegment, which is always
  // used nested under a city ('$citiesSegment/$cityId/$neighborhoodsSegment').
  static const String neighborhoods = '/neighborhoods';
  static const String personImagesSegment = 'images';
  static const String personRelationshipsSegment = 'relationships';
  // Flat "all mine" endpoint (row 9.11) — separate from personRelationshipsSegment, which is
  // always used nested under a person ('$persons/$personId/$personRelationshipsSegment').
  static const String personRelationships = '/person-relationships';
}
