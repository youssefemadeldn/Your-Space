/// Shared between `PersonOccasionHistoryEntry` and `EventGuest` — the backend
/// reuses this exact enum for both. Lives in core because both the people and
/// events features need it.
///
/// The backend serializes enums as their raw C# member name via
/// `JsonStringEnumConverter()` with no naming-policy override (`Program.cs:21`)
/// — i.e. PascalCase on the wire (`"WhatsApp"`, `"PhoneCall"`, `"Physical"`),
/// not the lowerCamelCase Dart identifiers below. [fromWire]/[toWire] bridge
/// that; never use `.name`/`.values.byName()` directly against JSON.
enum InviteMethod {
  whatsApp,
  phoneCall,
  physical;

  static InviteMethod fromWire(String value) => switch (value) {
        'WhatsApp' => InviteMethod.whatsApp,
        'PhoneCall' => InviteMethod.phoneCall,
        'Physical' => InviteMethod.physical,
        _ => throw FormatException('Unknown InviteMethod wire value: $value'),
      };

  String toWire() => switch (this) {
        InviteMethod.whatsApp => 'WhatsApp',
        InviteMethod.phoneCall => 'PhoneCall',
        InviteMethod.physical => 'Physical',
      };
}
