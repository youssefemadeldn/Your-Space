class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String confirmEmail = '/confirm-email';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String changePassword = '/change-password';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String settings = '/settings';

  static const String groups = '/groups';

  static const String people = '/people';
  // Replaces the old flat personForm route/person_form_screen.dart/
  // person_form_cubit/ (Sprint 4's 4-step wizard rebuild).
  static const String personWizard = '/people/wizard';
  static const String personDetails = '/people/details';
  static const String classificationManagement = '/classification/manage';

  static const String events = '/events';
  static const String eventForm = '/events/form';
  static const String eventDetails = '/events/details';
  static const String eventGuests = '/events/guests';
  static const String addGuests = '/events/guests/add';
  static const String reciprocitySuggestions = '/events/guests/reciprocity-suggestions';

  static const String unknown = '/unknown';
}
