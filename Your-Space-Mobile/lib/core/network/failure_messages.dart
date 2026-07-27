import 'package:flutter/foundation.dart';

import 'failure.dart';

/// Single source of truth for user-facing error strings — never duplicated
/// per feature. Feature layers import as:
/// `import 'package:your_space_mobile/core/network/failure_messages.dart' as core;`
String failureToMessage(Failure failure) => switch (failure) {
      NetworkFailure() => 'No internet connection',
      UnauthorizedFailure() => 'Session expired. Please sign in again',
      CacheFailure() => 'Local storage error',
      ValidationFailure(message: final m) => m,
      ServerFailure(statusCode: final code, message: final m) =>
        kReleaseMode ? 'Something went wrong. Please try again.' : '[$code] $m',
      UnexpectedFailure(message: final m) =>
        kReleaseMode ? 'Unexpected error' : (m.isEmpty ? 'Unexpected error' : m),
      Failure() => 'Unexpected error',
    };
