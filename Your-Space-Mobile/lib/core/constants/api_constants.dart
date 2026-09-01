class ApiConstants {
  ApiConstants._();

  // Android emulator alias for the host machine's localhost. Swap this to your
  // machine's LAN IP when testing on a physical device or iOS simulator.
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

  // Base segments only — nested paths (e.g. '$events/$eventId/guests') are
  // interpolated at the datasource call site.
  static const String groups = '/groups';
  static const String persons = '/persons';
  static const String events = '/events';
}
