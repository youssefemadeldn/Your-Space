import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;

/// Auth errorCodes whose backend `message` is always safe and correct to show
/// the user as-is. Core's [core.failureToMessage] hides `ServerFailure`
/// messages behind a generic string in release builds, which would be wrong
/// for these — they're user-facing validation/status text, not leaky
/// internals.
const _passthroughErrorCodes = {
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

/// Feature-level override of [core.failureToMessage] for the Auth feature.
/// `Auth.InvalidCredentials` is deliberately not handled here — it arrives as
/// [UnauthorizedFailure], which carries no backend message at all, so the
/// Login screen shows its own hardcoded copy for that one case instead.
String failureToMessage(Failure failure) => switch (failure) {
      ServerFailure(errorCode: final code, message: final m) when _passthroughErrorCodes.contains(code) => m,
      _ => core.failureToMessage(failure),
    };
