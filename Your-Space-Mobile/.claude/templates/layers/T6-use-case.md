---
name: T6-use-case
governed-by: §2 Rule 4 gate (create only when condition is met) · §3 (DI: @injectable)
di-annotation: "@injectable"
---

# T6 — Use Case

> ⚠️ **§2 Rule 4 gate — only create this file if at least one condition is true:**
>
> **(a)** This operation is called from **two or more cubits**, OR
> **(b)** This operation has **non-trivial domain logic** beyond a single repository call
>
> **If neither applies:** delete this file. Call the repository directly from the cubit — no use case needed.

Replace all `<Placeholder>` tokens before use.

---

## `domain/use_cases/<verb>_<noun>_use_case.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:booksplatform/core/network/failure.dart';
import '../entities/<entity>.dart';
import '../repositories/base_<feature>_repository.dart';
// Add second repository import here if combining calls:
// import '../repositories/base_<other>_repository.dart';

@injectable
class <Verb><Noun>UseCase {
  final <Feature>Repository _repository;
  // If combining two repositories:
  // final <Other>Repository _otherRepository;

  <Verb><Noun>UseCase(this._repository);

  Future<Either<Failure, <ReturnType>>> call(<Params>) =>
      _repository.<method>(<args>);

  // For non-trivial logic combining multiple calls:
  // Future<Either<Failure, <ReturnType>>> call(<Params>) async {
  //   final first = await _repository.<method1>(<args>);
  //   return first.fold(Left.new, (data) => _otherRepository.<method2>(data));
  // }
}
```

---

## Notes

- **`call()` naming is convention:** cubits can then write `await _useCase(<args>)` using Dart's callable class syntax — cleaner than `await _useCase.execute(<args>)`.
- **Inject both repositories when combining calls:** each cubit only injects the use case, not the repositories directly. The use case is the coordination point.
- **`@injectable` (factory), not `@lazySingleton`:** use cases have no state. Making them singletons has no benefit and misleads readers about lifecycle.
- **Cubits call use cases the same way they call repositories:** `final result = await _useCase(<args>); result.fold(...)`. No special cubit handling needed.
