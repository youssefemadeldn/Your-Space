import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/router/app_routes.dart';
import 'package:your_space_mobile/core/router/session_redirect.dart';
import 'package:your_space_mobile/core/storage/app_preferences_helper.dart';
import 'package:your_space_mobile/core/storage/secure_storage_helper.dart';

class MockAppPreferencesHelper extends Mock implements AppPreferencesHelper {}

class MockSecureStorageHelper extends Mock implements SecureStorageHelper {}

void main() {
  late MockAppPreferencesHelper preferences;
  late MockSecureStorageHelper secureStorage;

  setUp(() {
    preferences = MockAppPreferencesHelper();
    secureStorage = MockSecureStorageHelper();
    when(() => preferences.hasSeenOnboarding()).thenReturn(true);
  });

  test('redirects to onboarding when it has never been seen, regardless of session state', () async {
    when(() => preferences.hasSeenOnboarding()).thenReturn(false);
    when(() => secureStorage.getRememberMe()).thenAnswer((_) async => true);
    when(() => secureStorage.getToken()).thenAnswer((_) async => 'access-token');

    final result = await resolveSplashRedirect(preferences, secureStorage);

    expect(result, AppRoutes.onboarding);
    verifyNever(() => secureStorage.getRememberMe());
  });

  test('redirects to home when remembered and a token is present', () async {
    when(() => secureStorage.getRememberMe()).thenAnswer((_) async => true);
    when(() => secureStorage.getToken()).thenAnswer((_) async => 'access-token');

    final result = await resolveSplashRedirect(preferences, secureStorage);

    expect(result, AppRoutes.home);
  });

  test('redirects to login without checking the token when remember-me is off', () async {
    when(() => secureStorage.getRememberMe()).thenAnswer((_) async => false);

    final result = await resolveSplashRedirect(preferences, secureStorage);

    expect(result, AppRoutes.login);
    verifyNever(() => secureStorage.getToken());
  });

  test('redirects to login when remembered but no token is present', () async {
    when(() => secureStorage.getRememberMe()).thenAnswer((_) async => true);
    when(() => secureStorage.getToken()).thenAnswer((_) async => null);

    final result = await resolveSplashRedirect(preferences, secureStorage);

    expect(result, AppRoutes.login);
  });
}
