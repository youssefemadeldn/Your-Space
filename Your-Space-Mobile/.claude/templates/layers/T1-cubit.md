---
name: T1-cubit
governed-by: §4 (state design) · §3 (DI: @injectable) · §2 Rule 5 (action/query split)
di-annotation: "@injectable"
---

# T1 — Cubit + State

Two files per cubit concern. Replace all `<Placeholder>` tokens before use.

---

## Cubit — `presentation/cubit/<action>_cubit/<action>_cubit.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:booksplatform/core/network/failure_messages.dart' as core;
import '../../domain/repositories/base_<feature>_repository.dart';
import '<action>_state.dart';

@injectable
class <Action>Cubit extends Cubit<<Action>State> {
  final <Feature>Repository _repository;
  // If §2 Rule 4 applies, replace above with:
  // final <Verb><Noun>UseCase _useCase;

  <Action>Cubit(this._repository) : super(const <Action>Initial());

  Future<void> <action>(<Params>) async {
    emit(const <Action>Loading());
    final result = await _repository.<method>(<args>);
    result.fold(
      (failure) => emit(<Action>Error(core.failureToMessage(failure))),
      (data)    => emit(<Action>Success(data)),
    );
  }
}
```

---

## State — `presentation/cubit/<action>_cubit/<action>_state.dart`

```dart
import 'package:equatable/equatable.dart';

import '../../domain/entities/<entity>.dart';

sealed class <Action>State extends Equatable {
  const <Action>State();
  @override
  List<Object?> get props => const [];
}

final class <Action>Initial extends <Action>State {
  const <Action>Initial();
}

final class <Action>Loading extends <Action>State {
  const <Action>Loading();
}

final class <Action>Success extends <Action>State {
  final <DataType> data;
  const <Action>Success(this.data);
  @override
  List<Object?> get props => [data];
}

final class <Action>Error extends <Action>State {
  final String message;
  const <Action>Error(this.message);
  @override
  List<Object?> get props => [message];
}
```

---

## Notes

- **Action/query split (§2 Rule 5):** if the feature has both mutations and reads, use two separate cubits — `<Feature>ActionCubit` and `<Feature>ListCubit`. Never put both concerns in one cubit.
- **Never `@lazySingleton` for a cubit** — the sole exception is `CartCubit` (CLAUDE.md DI table). All other cubits are `@injectable` (factory).
- **`as core` alias is required** for `failureToMessage` in any cubit that also imports a feature-level `failure_messages.dart`. Use it consistently in all cubits for uniformity.
- **Use case swap-in:** if §2 Rule 4 applies, inject `<Verb><Noun>UseCase` instead of the repository and call `await _useCase(<args>)`.
- **`BlocProvider`** is created in `AppRouter.generateRoute`, never inside the screen widget.
