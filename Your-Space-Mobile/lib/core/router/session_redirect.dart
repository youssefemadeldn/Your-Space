import '../storage/app_preferences_helper.dart';
import '../storage/secure_storage_helper.dart';
import 'app_routes.dart';

/// Decides where the splash route sends the user. Onboarding takes priority
/// over everything else — shown once, on the very first launch ever,
/// regardless of login state; once [AppPreferencesHelper.hasSeenOnboarding]
/// is true, it's never shown again. After that: [AppRoutes.home] only when
/// the last login had "remember me" checked AND an access token is still
/// persisted; [AppRoutes.login] otherwise. A present-but-expired token isn't
/// rejected here — that's already handled downstream by AuthInterceptor's
/// silent refresh / forced logout on the first authenticated request.
Future<String> resolveSplashRedirect(
  AppPreferencesHelper preferences,
  SecureStorageHelper secureStorage,
) async {
  if (!preferences.hasSeenOnboarding()) return AppRoutes.onboarding;

  final rememberMe = await secureStorage.getRememberMe();
  if (!rememberMe) return AppRoutes.login;

  final token = await secureStorage.getToken();
  if (token == null || token.isEmpty) return AppRoutes.login;

  return AppRoutes.home;
}
