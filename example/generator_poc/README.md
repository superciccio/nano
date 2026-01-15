# Nano Generator PoC

This directory demonstrates a Proof of Concept for a code-generation based approach to Nano, aiming for high developer velocity and minimal boilerplate.

## The "Today" Solution

This PoC proves that **today** (using `build_runner`), we can achieve a clean, "SwiftUI-like" developer experience where:
1.  **Logic is simple:** Standard Dart fields, no manual `Atom` boilerplate.
2.  **UI is implicit:** Widgets track state automatically, no manual `.watch()` calls.

## Comparison

### 1. Vanilla Flutter
*   **Pros:** No dependencies.
*   **Cons:** `setState` is manual and coarse. Logic is coupled to UI.

### 2. Classic Nano
*   **Pros:** Explicit control, no codegen.
*   **Cons:** Verbose. Requires manual `Atom` definition and explicit `Watch` widgets.

### 3. PoC Nano (Generated)
*   **Pros:**
    *   **Clean Logic:**
        ```dart
        @nano
        abstract class _Counter extends NanoLogic {
            @state int count = 0; // Standard field!
            void increment() => count++; // Standard mutation!
        }
        class Counter = _Counter with _$Counter;
        ```
    *   **Implicit UI:**
        ```dart
        NanoConsumer(builder: (context) {
            final logic = context.use<Counter>();
            return Text('${logic.count}'); // Updates automatically!
        })
        ```
*   **Cons:**
    *   Requires `dart run build_runner build`.

## How to Run

1.  **Generate Code:**
    ```bash
    cd example/generator_poc/example_app
    flutter pub get
    dart run build_runner build
    ```
    *(Note: `poc_nano_counter.g.dart` is currently checked in for reference)*

2.  **Run App:**
    ```bash
    flutter run
    ```
