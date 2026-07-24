---
name: T5-models
governed-by: §7 (response model: fromJson + toEntity only) · §8 (request model: toJson only, omit nulls)
di-annotation: "none — plain Dart classes, instantiated inline"
---

# T5 — Response Model + Request Model

Two files per feature operation. Replace all `<Placeholder>` tokens before use.

---

## Response Model — `data/models/<resource>_response.dart`

```dart
import '../../../domain/entities/<entity>.dart';

class <Resource>Response {
  final String id;
  final String <field>;
  final String? <optionalField>;

  const <Resource>Response({
    required this.id,
    required this.<field>,
    this.<optionalField>,
  });

  factory <Resource>Response.fromJson(Map<String, dynamic> json) =>
      <Resource>Response(
        id: json['id'] as String,
        <field>: json['<apiKey>'] as String,
        <optionalField>: json['<apiKey>'] as String?,
      );

  <Entity> toEntity() => <Entity>(
        id: id,
        <field>: <field>,
        <optionalField>: <optionalField>,
      );
}
```

---

## Request Model — `data/models/<action>_request.dart`

```dart
class <Action>Request {
  final String <requiredField>;
  final String? <optionalField>;

  const <Action>Request({
    required this.<requiredField>,
    this.<optionalField>,
  });

  Map<String, dynamic> toJson() => {
        '<apiKey>': <requiredField>,
        if (<optionalField> != null) '<apiKey>': <optionalField>,
      };
}
```

---

## Notes

- **Response model responsibilities (§7):** `fromJson` and `toEntity` only. No `Equatable`, no `toJson`, no business logic. Instantiated once, mapped to entity via `toEntity()`, then discarded — never passed to domain or presentation.
- **Request model responsibilities (§8):** `toJson` only. No `fromJson`, no `Equatable`. Instantiated at the call site and passed to the data source method.
- **Omit null optionals from `toJson` (§8):** use `if (field != null) 'key': field` rather than sending `"field": null`, unless the backend explicitly requires null to mean "clear this field".
- **Explicit casts in `fromJson`:** always cast JSON values explicitly (`as String`, `as int`, `as String?`). Never leave them as `dynamic`.
- **`unwrapServiceResult` wraps `fromJson`:** when the backend uses the envelope pattern, the `fromJson` lambda in the data source receives the inner `data` object — not the outer envelope. The response model's `fromJson` only ever sees the inner object. See §11 and T2.
