import 'package:flutter_test/flutter_test.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/failure_messages.dart';

void main() {
  group('whitelisted errorCodes pass the backend message straight through', () {
    const whitelisted = {
      'Auth.Register.EmailExists',
      'Auth.AccountLocked',
      'Auth.User.NotFound',
      'Auth.ConfirmEmail.InvalidRequest',
      'Auth.ConfirmEmail.Failed',
      'Auth.ResetPassword.InvalidRequest',
      'Otp.Expired',
      'Otp.Invalid',
      'Otp.LockedOut',
    };

    for (final code in whitelisted) {
      test(code, () {
        final failure = ServerFailure(statusCode: 400, message: 'backend message for $code', errorCode: code);
        expect(failureToMessage(failure), 'backend message for $code');
      });
    }
  });

  test('delegates to core.failureToMessage for a non-whitelisted ServerFailure', () {
    const failure = ServerFailure(statusCode: 500, message: 'boom', errorCode: 'Server.Error');
    // core's failureToMessage genericizes ServerFailure outside debug mode,
    // but always includes the message in debug builds (which is how tests run).
    expect(failureToMessage(failure), contains('boom'));
  });

  test('delegates to core.failureToMessage for NetworkFailure', () {
    expect(failureToMessage(const NetworkFailure()), 'No internet connection');
  });

  test('delegates to core.failureToMessage for ValidationFailure (already passes through in core)', () {
    const failure = ValidationFailure(message: 'Validation message', errorCode: 'Validation.Failed');
    expect(failureToMessage(failure), 'Validation message');
  });
}
