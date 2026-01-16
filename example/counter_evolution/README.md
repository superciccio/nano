# Counter Evolution

This example demonstrates the evolution of Nano from its "Classic" manual style to the "Modern" generated style.

## Key Concepts

1.  **Classic Nano (`classic_counter.dart`)**:
    *   Manual `Atom` definition.
    *   Explicit `.watch()` in UI.
    *   No code generation.

2.  **Modern Nano (`modern_counter.dart`)**:
    *   `@nano` annotation on Logic.
    *   Standard Dart fields (`@state`).
    *   `NanoStatelessWidget` for implicit UI updates.
    *   Requires `dart run build_runner build`.

## How to Run

```bash
flutter pub get
dart run build_runner build
flutter run
```
