---
name: T4-entity
governed-by: §2 Rule 3 (no data-layer imports) · Equatable for BLoC state comparison
di-annotation: "none — plain Dart class, no DI registration"
---

# T4 — Domain Entity

Single file. Replace all `<Placeholder>` tokens before use.

---

## `domain/entities/<entity>.dart`

```dart
import 'package:equatable/equatable.dart';

class <Entity> extends Equatable {
  final String id;
  final String <field>;
  final String? <optionalField>;

  const <Entity>({
    required this.id,
    required this.<field>,
    this.<optionalField>,
  });

  @override
  List<Object?> get props => [id, <field>, <optionalField>];
}
```

---

## Notes

- **No data-layer imports (§2 Rule 3):** the only allowed import is `package:equatable/equatable.dart`. Never import anything from `data/` — no models, no request types, no Dio types.
- **No `fromJson` or `toJson`:** those belong on response/request models in `data/models/`. Entities are pure domain objects — instantiated by `toEntity()` on the response model, never parsed directly from JSON.
- **`Equatable` is required:** BLoC uses `==` comparison to decide whether to rebuild. Without it, identical state objects trigger unnecessary rebuilds.
- **Nullable fields:** use `?` for fields that may be absent from the API response. Null-to-entity mapping happens in `<Resource>Response.toEntity()` — not here.
- **No business logic:** entities are data bags. Logic that derives values from entity fields belongs in use cases or cubits.
