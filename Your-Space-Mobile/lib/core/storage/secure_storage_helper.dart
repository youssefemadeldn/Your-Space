import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../constants/app_constants.dart';

@lazySingleton
class SecureStorageHelper {
  final FlutterSecureStorage _storage;

  SecureStorageHelper(this._storage);

  Future<void> saveToken(String token) => saveString(AppConstants.kTokenKey, token);

  Future<String?> getToken() => getString(AppConstants.kTokenKey);

  Future<void> deleteToken() => deleteKey(AppConstants.kTokenKey);

  Future<void> saveRefreshToken(String token) =>
      saveString(AppConstants.kRefreshTokenKey, token);

  Future<String?> getRefreshToken() => getString(AppConstants.kRefreshTokenKey);

  Future<void> deleteRefreshToken() => deleteKey(AppConstants.kRefreshTokenKey);

  Future<void> saveRememberMe(bool value) =>
      saveString(AppConstants.kRememberMeKey, value ? 'true' : 'false');

  Future<bool> getRememberMe() async =>
      (await getString(AppConstants.kRememberMeKey)) == 'true';

  Future<void> deleteRememberMe() => deleteKey(AppConstants.kRememberMeKey);

  Future<void> saveString(String key, String value) => _storage.write(key: key, value: value);

  Future<String?> getString(String key) => _storage.read(key: key);

  Future<void> deleteKey(String key) => _storage.delete(key: key);

  Future<void> clearAll() => _storage.deleteAll();

  /// Clears everything that constitutes a logged-in session.
  Future<void> clearSession() async {
    await deleteToken();
    await deleteRefreshToken();
    await deleteRememberMe();
  }
}
