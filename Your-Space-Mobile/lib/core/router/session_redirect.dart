import '../storage/secure_storage_helper.dart';
import 'app_routes.dart';

/// Decides where the splash route sends the user: [AppRoutes.home] only when
/// the last login had "remember me" checked AND an access token is still
/// persisted; [AppRoutes.login] otherwise. A present-but-expired token isn't
/// rejected here — that's already handled downstream by AuthInterceptor's
/// silent refresh / forced logout on the first authenticated request.
Future<String> resolveSplashRedirect(SecureStorageHelper secureStorage) async {
  final rememberMe = await secureStorage.getRememberMe();
  if (!rememberMe) return AppRoutes.login;

  final token = await secureStorage.getToken();
  if (token == null || token.isEmpty) return AppRoutes.login;

  return AppRoutes.home;
}
