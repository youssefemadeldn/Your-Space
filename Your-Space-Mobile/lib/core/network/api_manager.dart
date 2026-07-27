import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'api_result.dart';
import 'failure.dart';

typedef JsonMapper<T> = T Function(Object? json);

/// The sole error boundary for HTTP calls. Converts every [DioException] to
/// `Either<Failure, T>` — callers never see a raw exception.
@lazySingleton
class ApiManager {
  final Dio _dio;

  ApiManager(this._dio);

  Future<Either<Failure, T>> get<T>({
    required String path,
    required JsonMapper<T> fromJson,
    Map<String, dynamic>? queryParameters,
  }) =>
      _request<T>(() => _dio.get(path, queryParameters: queryParameters), fromJson);

  Future<Either<Failure, T>> post<T>({
    required String path,
    required JsonMapper<T> fromJson,
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) =>
      _request<T>(() => _dio.post(path, data: data, queryParameters: queryParameters), fromJson);

  Future<Either<Failure, T>> put<T>({
    required String path,
    required JsonMapper<T> fromJson,
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) =>
      _request<T>(() => _dio.put(path, data: data, queryParameters: queryParameters), fromJson);

  Future<Either<Failure, T>> patch<T>({
    required String path,
    required JsonMapper<T> fromJson,
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) =>
      _request<T>(() => _dio.patch(path, data: data, queryParameters: queryParameters), fromJson);

  Future<Either<Failure, T>> delete<T>({
    required String path,
    required JsonMapper<T> fromJson,
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) =>
      _request<T>(
          () => _dio.delete(path, data: data, queryParameters: queryParameters), fromJson);

  Future<Either<Failure, T>> _request<T>(
    Future<Response> Function() call,
    JsonMapper<T> fromJson,
  ) async {
    final result = await _safeCall(call, fromJson);
    return switch (result) {
      ApiSuccess<T>(:final data) => Right(data),
      ApiFailure<T>(:final failure) => Left(failure),
    };
  }

  Future<ApiResult<T>> _safeCall<T>(
    Future<Response> Function() call,
    JsonMapper<T> fromJson,
  ) async {
    try {
      final response = await call();
      return ApiSuccess(fromJson(response.data));
    } on DioException catch (e) {
      return ApiFailure(_mapDioError(e));
    } catch (e) {
      return ApiFailure(UnexpectedFailure(message: e.toString()));
    }
  }

  Failure _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure();

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final errorCode = _extractErrorCode(e.response?.data);
        final message = _extractMessage(e.response?.data) ?? e.message ?? 'Server error';

        if (statusCode == null) {
          // A badResponse with no status code is not a real HTTP status —
          // ServerFailure only ever carries a genuine HTTP status.
          return UnexpectedFailure(message: message, errorCode: errorCode);
        }
        if (statusCode == 401) {
          return UnauthorizedFailure(errorCode: errorCode);
        }
        if (statusCode == 422) {
          return ValidationFailure(message: message, errorCode: errorCode);
        }
        return ServerFailure(statusCode: statusCode, message: message, errorCode: errorCode);

      case DioExceptionType.cancel:
        return const UnexpectedFailure(message: 'Request cancelled');

      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return UnexpectedFailure(message: e.message ?? 'Unexpected error');
    }
  }

  // Defensive: a non-Map body, a missing key, or a non-string value all
  // resolve to null rather than throwing — not every endpoint sends one.
  String? _extractErrorCode(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    final code = data['errorCode'];
    return code is String ? code : null;
  }

  String? _extractMessage(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    final message = data['message'];
    return message is String ? message : null;
  }
}
