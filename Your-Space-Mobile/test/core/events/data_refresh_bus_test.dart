import 'package:flutter_test/flutter_test.dart';

import 'package:your_space_mobile/core/events/data_refresh_bus.dart';

void main() {
  late DataRefreshBus bus;

  setUp(() => bus = DataRefreshBus());

  test('notify() fans the scope out to every listener', () async {
    final expectation1 = expectLater(bus.stream, emits(DataScope.people));
    final expectation2 = expectLater(bus.stream, emits(DataScope.people));

    bus.notify(DataScope.people);

    await expectation1;
    await expectation2;
  });

  test('each notify() call carries only its own scope', () async {
    final received = <DataScope>[];
    final sub = bus.stream.listen(received.add);

    bus.notify(DataScope.groups);
    bus.notify(DataScope.eventGuests);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(received, [DataScope.groups, DataScope.eventGuests]);
  });

  test('dispose() closes the stream', () async {
    bus.dispose();
    await expectLater(bus.stream, emitsDone);
  });
}
