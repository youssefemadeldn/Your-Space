import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import '../entities/user_profile.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserProfile>> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  });

  Future<Either<Failure, UserProfile>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, Unit>> confirmEmail({
    required String email,
    required String code,
  });

  Future<Either<Failure, Unit>> resendConfirmationEmail({required String email});

  Future<Either<Failure, Unit>> forgotPassword({required String email});

  Future<Either<Failure, Unit>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmNewPassword,
  });

  Future<Either<Failure, Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  });
}
