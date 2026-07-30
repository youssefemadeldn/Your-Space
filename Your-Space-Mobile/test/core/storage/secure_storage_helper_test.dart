import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/constants/app_constants.dart';
import 'package:your_space_mobile/core/storage/secure_storage_helper.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage storage;
  late SecureStorageHelper helper;

  setUp(() {
    storage = MockFlutterSecureStorage();
    helper = SecureStorageHelper(storage);
  });

  group('rememberMe', () {
    test('saveRememberMe(true) writes the string "true"', () async {
      when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      await helper.saveRememberMe(true);

      verify(() => storage.write(key: AppConstants.kRememberMeKey, value: 'true')).called(1);
    });

    test('saveRememberMe(false) writes the string "false"', () async {
      when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      await helper.saveRememberMe(false);

      verify(() => storage.write(key: AppConstants.kRememberMeKey, value: 'false')).called(1);
    });

    test('getRememberMe() returns true only when the stored value is exactly "true"', () async {
      when(() => storage.read(key: AppConstants.kRememberMeKey)).thenAnswer((_) async => 'true');
      expect(await helper.getRememberMe(), isTrue);

      when(() => storage.read(key: AppConstants.kRememberMeKey)).thenAnswer((_) async => 'false');
      expect(await helper.getRememberMe(), isFalse);
    });

    test('getRememberMe() returns false when never set', () async {
      when(() => storage.read(key: AppConstants.kRememberMeKey)).thenAnswer((_) async => null);

      expect(await helper.getRememberMe(), isFalse);
    });
  });

  group('clearSession', () {
    test('deletes the access token, refresh token, and remember-me flag', () async {
      when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});

      await helper.clearSession();

      verify(() => storage.delete(key: AppConstants.kTokenKey)).called(1);
      verify(() => storage.delete(key: AppConstants.kRefreshTokenKey)).called(1);
      verify(() => storage.delete(key: AppConstants.kRememberMeKey)).called(1);
    });
  });
}
