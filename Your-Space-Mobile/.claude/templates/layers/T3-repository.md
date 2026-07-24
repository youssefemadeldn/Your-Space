---
name: T3-repository
governed-by: §2 Rule 3 (entities not models) · §3 (DI: @LazySingleton(as: Repo))
di-annotation: "@LazySingleton(as: <Feature>Repository)"
---

# T3 — Repository Impl

Single file. Replace all `<Placeholder>` tokens before use.

---

## `data/repositories/<feature>_repository_impl.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:booksplatform/core/network/failure.dart';
import '../../domain/entities/<entity>.dart';
import '../../domain/repositories/base_<feature>_repository.dart';
import '../datasources/<feature>_remote_data_source_impl.dart';
import '../models/<action>_request.dart';

@LazySingleton(as: <Feature>Repository)
class <Feature>RepositoryImpl implements <Feature>Repository {
  final <Feature>RemoteDataSourceImpl _remote;
  // When local source exists, also inject:
  // final <Feature>LocalDataSourceImpl _local;

  <Feature>RepositoryImpl(this._remote);

  @override
  Future<Either<Failure, <Entity>>> get<Resource>(String id) async {
    final result = await _remote.get<Resource>(id);
    return result.fold(Left.new, (response) => Right(response.toEntity()));
  }

  @override
  Future<Either<Failure, Unit>> create<Resource>(<Action>Request request) =>
      _remote.create<Resource>(request);
}
```

---

## Notes

- **`Left.new` shorthand:** equivalent to `(failure) => Left(failure)` — prefer it for the fold's left arm when no transformation is needed.
- **`toEntity()` is the only mapping here (§2 Rule 3):** response models never cross into domain or presentation. The repository impl is the sole place that calls `toEntity()`.
- **Void operations:** when no transformation is needed (`Either<Failure, Unit>`), the method can be a single expression returning the data source call directly — no `async`/`await` needed.
- **Named injections when local source exists:** annotate constructor params with `@Named('remote')` and `@Named('local')`. Change `_remote`'s type to the abstract contract `Base<Feature>DataSource` (read-only). Keep `_local` typed as its **concrete** `<Feature>LocalDataSourceImpl` class — it exposes `save*` write methods that populate the cache and have no remote equivalent, so they aren't on the shared interface.
- **Do not return response models from the domain contract:** the abstract repository (`base_<feature>_repository.dart`) must declare return types as entities and primitives only. Never change it to return a `*Response` type.
