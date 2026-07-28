class RegexHelper {
  RegexHelper._();

  static final RegExp email = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');

  static final RegExp egyptianPhone = RegExp(r'^01[0125][0-9]{8}$');

  static final RegExp password = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');

  static final RegExp strongPassword =
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$');

  /// Matches the backend's international phone format exactly
  /// (`RegisterDto.PhoneNumber` validator): optional leading `+`, first digit
  /// 1-9, then 8-14 more digits, e.g. `+201234567890`.
  static final RegExp internationalPhone = RegExp(r'^\+?[1-9]\d{7,14}$');

  /// Matches the backend's strong-password rule exactly (any non-alphanumeric
  /// character counts, unlike [strongPassword]'s fixed symbol set) — used
  /// wherever a password field must accept everything the backend accepts.
  static final RegExp accountPassword =
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z0-9]).{8,}$');

  static final RegExp username = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  static final RegExp numericOnly = RegExp(r'^[0-9]+$');

  static final RegExp arabicText = RegExp(r'^[؀-ۿ\s]+$');

  static final RegExp noSpecialChars = RegExp(r'^[a-zA-Z0-9\s]+$');

  static bool validate(RegExp pattern, String value) => pattern.hasMatch(value);
}
