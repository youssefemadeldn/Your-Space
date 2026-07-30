import 'package:easy_localization/easy_localization.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;

/// `Person.NotFound` gets a specific, localized message (matches the message
/// the details screen already showed pre-integration) instead of falling
/// through to core's generic release-mode `ServerFailure` text.
String failureToMessage(Failure failure) => switch (failure) {
      ServerFailure(errorCode: 'Person.NotFound') => 'people.details.notFound'.tr(),
      _ => core.failureToMessage(failure),
    };
