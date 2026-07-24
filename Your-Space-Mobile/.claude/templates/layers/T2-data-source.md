---
name: T2-data-source
governed-by: §2 Rule 1 (no auth) · §2 Rule 2 (no try/catch) · §3 (DI: @lazySingleton) · §11 (API envelope)
di-annotation: "@lazySingleton"
---

# T2 — Remote Data Source

Single file. Replace all `<Placeholder>` tokens before use.

---

## `data/datasources/<feature>_remote_data_source_impl.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:booksplatform/core/network/api_manager.dart';
import 'package:booksplatform/core/network/api_envelope.dart';
import 'package:booksplatform/core/network/failure.dart';
import 'package:booksplatform/core/constants/api_constants.dart';
import '../models/<resource>_response.dart';
import '../models/<action>_request.dart';

@lazySingleton
class <Feature>RemoteDataSourceImpl {
  final ApiManager _api;

  <Feature>RemoteDataSourceImpl(this._api);

  Future<Either<Failure, <Resource>Response>> get<Resource>(String id) =>
      _api.get<<Resource>Response>(
        path: '${ApiConstants.<endpoint>}/$id',
        fromJson: (json) => unwrapServiceResult(
          json,
          (inner) => <Resource>Response.fromJson(inner as Map<String, dynamic>),
        ),
      );

  Future<Either<Failure, Unit>> create<Resource>(<Action>Request request) =>
      _api.post<Unit>(
        path: ApiConstants.<endpoint>,
        data: request.toJson(),
        fromJson: (_) => unit,
      );
}
```

---

## Notes

- **No auth logic (§2 Rule 1):** never read a token, set a header, or call an auth service. `AuthInterceptor` handles all of that transparently.
- **No try/catch (§2 Rule 2):** `ApiManager` is the sole error boundary. Return its `Either` directly — never wrap it.
- **`unwrapServiceResult` (§11):** use only when the backend wraps responses in `{ "success": true, "data": {...} }`. If the endpoint returns raw JSON, call `fromJson` directly on the response without the unwrapper. If the endpoint is void (delete, logout), use `fromJson: (_) => unit` and skip `unwrapServiceResult`.
- **Path constants:** all endpoint path strings live in `ApiConstants` — never inline a URL string in a data source.
- **When a local data source is needed:** introduce `base_<feature>_data_source.dart` (abstract contract, read operations only), annotate this file as `@Named('remote') @LazySingleton(as: Base<Feature>DataSource)` (binds *as* the interface — plain `@lazySingleton` leaves it unresolvable from the repository's abstract-typed parameter), and create `<feature>_local_data_source_impl.dart` annotated `@Named('local') @lazySingleton` with its own `save*` write methods. See CLAUDE.md local data source rule.
