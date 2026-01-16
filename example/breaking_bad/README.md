# Breaking Bad Quotes

This example demonstrates two ways to build the same app with Nano.

## 1. Classic Nano (Manual)
The original approach using manual `Atom` definitions and `NanoView`.
*   Entry point: `lib/main.dart`
*   Logic: `lib/breaking_bad_logic.dart`

## 2. Modern Nano (Generated)
The new approach using `@nano` code generation and `NanoComponent`.
*   Entry point: `lib/main_modern.dart`
*   Logic: `lib/modern/modern_breaking_bad_logic.dart`
*   UI: `lib/modern/modern_breaking_bad_app.dart`

## How to Run

**Classic:**
```bash
flutter run lib/main.dart
```

**Modern:**
1.  Generate code:
    ```bash
    dart run build_runner build
    ```
2.  Run:
    ```bash
    flutter run lib/main_modern.dart
    ```