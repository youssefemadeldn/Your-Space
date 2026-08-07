import 'dart:async';

import 'package:injectable/injectable.dart';

/// What kind of data changed. Kept separate from `events` on purpose:
/// `eventGuests` covers roster/status changes within one event (guest count,
/// invite progress) without forcing `HomeStatsCubit` — which only shows an
/// events *count*, never guest data — to refresh on every guest status flip.
enum DataScope { people, groups, events, eventGuests, profile }

/// Cross-tab/cross-route invalidation bus. `StatefulShellRoute.indexedStack`
/// keeps Home/Groups/People/Events/Settings branch cubits alive forever once
/// built, and mutation screens (PersonForm, EventForm, ...) are sibling
/// routes pushed on top rather than nested in a branch — so no navigation
/// event ever tells an already-built cubit that data changed elsewhere.
/// Action cubits call [notify] on a successful mutation; list/stats/detail
/// cubits subscribe to [stream] and re-fetch themselves.
@lazySingleton
class DataRefreshBus {
  final _controller = StreamController<DataScope>.broadcast();

  Stream<DataScope> get stream => _controller.stream;

  void notify(DataScope scope) => _controller.add(scope);

  @disposeMethod
  void dispose() => _controller.close();
}
