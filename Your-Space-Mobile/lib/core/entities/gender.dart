/// Shared between Auth (registration) and People (Person form) — lives in
/// core because both features need it.
///
/// The backend serializes enums as their raw C# member name via
/// `JsonStringEnumConverter()` with no naming-policy override (`Program.cs:21`)
/// — i.e. PascalCase on the wire (`"Male"`, `"Female"`), not the lowerCamelCase
/// Dart identifiers below. [fromWire]/[toWire] bridge that; never use
/// `.name`/`.values.byName()` directly against JSON.
enum Gender {
  male,
  female;

  static Gender fromWire(String value) => switch (value) {
        'Male' => Gender.male,
        'Female' => Gender.female,
        _ => throw FormatException('Unknown Gender wire value: $value'),
      };

  String toWire() => switch (this) {
        Gender.male => 'Male',
        Gender.female => 'Female',
      };
}
