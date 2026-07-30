/// Backend serializes enums as their raw C# member name (`Program.cs:21`,
/// `JsonStringEnumConverter()` with no naming-policy override) — PascalCase
/// on the wire, not the lowerCamelCase Dart identifiers below.
enum EventGuestStatus {
  notInvited,
  invited,
  skipped;

  static EventGuestStatus fromWire(String value) => switch (value) {
        'NotInvited' => EventGuestStatus.notInvited,
        'Invited' => EventGuestStatus.invited,
        'Skipped' => EventGuestStatus.skipped,
        _ => throw FormatException('Unknown EventGuestStatus wire value: $value'),
      };

  String toWire() => switch (this) {
        EventGuestStatus.notInvited => 'NotInvited',
        EventGuestStatus.invited => 'Invited',
        EventGuestStatus.skipped => 'Skipped',
      };
}
