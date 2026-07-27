import 'dart:async';

import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

import '../../constants/api_constants.dart';
import '../../router/app_routes.dart';
import '../../storage/secure_storage_helper.dart';
import '../api_envelope.dart';

/// Handles Bearer token injection and silent token-refresh on 401. Data
/// sources never touch a token directly — this is the single place auth
/// state affects a request.
class AuthInterceptor extends Interceptor {
  final SecureStorageHelper _secureStorage;
  final GoRouter _router;

  /// A bare Dio with no interceptors — used only to call the refresh
  /// endpoint and to retry a failed request, so it never re-enters this
  /// interceptor and can't recurse.
  final Dio _bareDio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
    ),
  );

  /// Shared across concurrent 401s so a burst of failing requests triggers
  /// exactly one refresh call instead of a refresh storm.
  Completer<String?>? _refreshCompleter;

  AuthInterceptor(this._secureStorage, this._router);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _secureStorage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isRefreshCall = err.requestOptions.path == ApiConstants.refreshToken;

    if (isRefreshCall) {
      // The refresh token itself is invalid/expired — no retry, straight to logout.
      await _logout();
      handler.next(err);
      return;
    }

    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final newAccessToken = await _refreshAccessToken();
    if (newAccessToken == null) {
      await _logout();
      handler.next(err);
      return;
    }

    try {
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final response = await _bareDio.fetch(retryOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<String?> _refreshAccessToken() async {
    final inFlight = _refreshCompleter;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<String?>();
    _refreshCompleter = completer;

    final newAccessToken = await _performRefresh();
    completer.complete(newAccessToken);
    _refreshCompleter = null;
    return newAccessToken;
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final response = await _bareDio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );
      final tokens = unwrapServiceResult(
        response.data,
        (inner) => inner as Map<String, dynamic>,
      );
      final newAccessToken = tokens['accessToken'] as String?;
      final newRefreshToken = tokens['refreshToken'] as String?;
      if (newAccessToken == null || newRefreshToken == null) return null;

      await _secureStorage.saveToken(newAccessToken);
      await _secureStorage.saveRefreshToken(newRefreshToken);
      return newAccessToken;
    } catch (_) {
      return null;
    }
  }

  Future<void> _logout() async {
    await _secureStorage.deleteToken();
    await _secureStorage.deleteRefreshToken();
    // `.go` (path-based), not `.goNamed` — safe even before a `/login`
    // GoRoute exists, since an unmatched path falls through to
    // AppRouter's errorBuilder instead of throwing.
    _router.go(AppRoutes.login);
  }
}
