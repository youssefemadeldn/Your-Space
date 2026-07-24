---
name: T7-screen
governed-by: §1.1 (flat file vs screen folder threshold) · §6 (layout: SafeArea, SingleChildScrollView) · §4 (BlocBuilder/BlocConsumer)
di-annotation: "none — screens are plain widgets; BlocProvider is created in AppRouter"
---

# T7 — Screen

Two variants. Choose based on the §1.1 threshold. Replace all `<Placeholder>` tokens before use.

---

## Variant A — Flat File (default)

Use when: total widget code is **under ~250 lines** and there is **no embedded `StatefulWidget`**.

### `presentation/pages/<feature>_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:booksplatform/core/widgets/app_loading_indicator.dart';
import 'package:booksplatform/core/widgets/error_state_widget.dart';
import '../cubit/<query>_cubit/<query>_cubit.dart';
import '../cubit/<query>_cubit/<query>_state.dart';

class <Feature>Screen extends StatelessWidget {
  const <Feature>Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<<Query>Cubit, <Query>State>(
          builder: (context, state) => switch (state) {
            <Query>Loading() => const AppLoadingIndicator(),
            <Query>Success(:final data) => _<Feature>Content(data: data),
            <Query>Error(:final message) => ErrorStateWidget(
                message: message,
                onRetry: () => context.read<<Query>Cubit>().<reload>(),
              ),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}

class _<Feature>Content extends StatelessWidget {
  final <DataType> data;
  const _<Feature>Content({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // content
        ],
      ),
    );
  }
}
```

---

## Variant B — Screen Folder (threshold crossed)

Use when: the file would exceed **~250 lines** OR any component is a `StatefulWidget` with its own controller or form.

### Folder structure

```
presentation/pages/<feature>_screen/
├── <feature>_screen.dart     ← only the screen widget; routing target; no private sub-widgets
├── <feature>_body.dart       ← main scrollable content
└── <feature>_shimmer.dart    ← all skeleton loaders for this screen in one file
```

### `<feature>_screen.dart` (folder variant)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:booksplatform/core/widgets/app_loading_indicator.dart';
import 'package:booksplatform/core/widgets/error_state_widget.dart';
import '../../cubit/<query>_cubit/<query>_cubit.dart';
import '../../cubit/<query>_cubit/<query>_state.dart';
import '<feature>_body.dart';
import '<feature>_shimmer.dart';

class <Feature>Screen extends StatelessWidget {
  const <Feature>Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<<Query>Cubit, <Query>State>(
          builder: (context, state) => switch (state) {
            <Query>Loading() => const <Feature>Shimmer(),
            <Query>Success(:final data) => <Feature>Body(data: data),
            <Query>Error(:final message) => ErrorStateWidget(
                message: message,
                onRetry: () => context.read<<Query>Cubit>().<reload>(),
              ),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}
```

---

## Notes

- **`BlocProvider` lives in `AppRouter`** — never create it inside the screen widget. The screen receives the cubit from the widget tree via `context.read<>()`.
- **`BlocConsumer` for action cubits:** if the screen also drives mutations (add, delete, update), wrap with `BlocConsumer<<Action>Cubit, <Action>State>` as the outer widget. Its `listener` handles side effects (show snack bar, trigger list refresh via the query cubit); its `builder` returns the `BlocBuilder` for the query cubit.
- **`SafeArea` at scaffold body level** on every screen (§6).
- **`Scaffold.bottomNavigationBar`** for pinned bottom buttons — not `Positioned(bottom: 0)` (§6).
- **`SingleChildScrollView`** for screens with tall/variable content — never stack fixed-height sections (§6).
- **Screen-specific components go in the screen folder** (Variant B), not in `widgets/`. The `widgets/` folder is strictly for components shared across two or more screens (§1.1).
- **No `states/` subfolder** — name files by visual concern (`<feature>_shimmer.dart`, `<feature>_body.dart`), keep flat inside the screen folder.
