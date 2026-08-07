import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/constants/api_constants.dart';
import 'package:your_space_mobile/core/network/api_envelope.dart';
import 'package:your_space_mobile/core/network/api_manager.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import '../models/auth_response.dart';
import '../models/change_password_request.dart';
import '../models/confirm_email_request.dart';
import '../models/forgot_password_request.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/resend_confirmation_email_request.dart';
import '../models/reset_password_request.dart';
import '../models/update_profile_request.dart';
import '../models/user_profile_response.dart';

@lazySingleton
class AuthRemoteDataSourceImpl {
  final ApiManager _api;

  AuthRemoteDataSourceImpl(this._api);

  Future<Either<Failure, UserProfileResponse>> register(RegisterRequest request) =>
      _api.post<UserProfileResponse>(
        path: ApiConstants.register,
        data: request.toJson(),
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => UserProfileResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, AuthResponse>> login(LoginRequest request) =>
      _api.post<AuthResponse>(
        path: ApiConstants.login,
        data: request.toJson(),
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => AuthResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, Unit>> confirmEmail(ConfirmEmailRequest request) =>
      _api.post<Unit>(
        path: ApiConstants.confirmEmail,
        data: request.toJson(),
        fromJson: (_) => unit,
      );

  Future<Either<Failure, Unit>> resendConfirmationEmail(
    ResendConfirmationEmailRequest request,
  ) =>
      _api.post<Unit>(
        path: ApiConstants.resendConfirmationEmail,
        data: request.toJson(),
        fromJson: (_) => unit,
      );

  Future<Either<Failure, Unit>> forgotPassword(ForgotPasswordRequest request) =>
      _api.post<Unit>(
        path: ApiConstants.forgotPassword,
        data: request.toJson(),
        fromJson: (_) => unit,
      );

  Future<Either<Failure, Unit>> resetPassword(ResetPasswordRequest request) =>
      _api.post<Unit>(
        path: ApiConstants.resetPassword,
        data: request.toJson(),
        fromJson: (_) => unit,
      );

  Future<Either<Failure, Unit>> changePassword(ChangePasswordRequest request) =>
      _api.post<Unit>(
        path: ApiConstants.changePassword,
        data: request.toJson(),
        fromJson: (_) => unit,
      );

  Future<Either<Failure, UserProfileResponse>> getProfile() =>
      _api.get<UserProfileResponse>(
        path: ApiConstants.profile,
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => UserProfileResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, UserProfileResponse>> updateProfile(UpdateProfileRequest request) =>
      _api.put<UserProfileResponse>(
        path: ApiConstants.profile,
        data: request.toJson(),
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => UserProfileResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, UserProfileResponse>> uploadAvatar(File file) async {
    final formData = FormData.fromMap({
      'File': await MultipartFile.fromFile(file.path),
    });
    return _api.post<UserProfileResponse>(
      path: ApiConstants.avatar,
      data: formData,
      fromJson: (json) => unwrapServiceResult(
        json,
        (inner) => UserProfileResponse.fromJson(inner as Map<String, dynamic>),
      ),
    );
  }

  Future<Either<Failure, UserProfileResponse>> removeAvatar() =>
      _api.delete<UserProfileResponse>(
        path: ApiConstants.avatar,
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => UserProfileResponse.fromJson(inner as Map<String, dynamic>),
        ),
      );
}
