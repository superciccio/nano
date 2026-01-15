# Nano Generator PoC

This directory demonstrates a Proof of Concept for a code-generation based approach to Nano, aiming for higher developer velocity and reduced boilerplate, inspired by SwiftUI's simplicity.

## Structure

*   `nano_annotations`: Defines `@nano` and `@state`.
*   `nano_generator`: Implements the `build_runner` generator.
*   `example_app`: A Flutter app comparing Vanilla, Classic Nano, and the new PoC approach.

## Comparison

### 1. Vanilla Flutter
*   **Pros:** No dependencies.
*   **Cons:** `setState` rebuilds entire widget or requires complex `ValueListenableBuilder` nesting. Logic mixed with UI in `State` class.

### 2. Classic Nano
*   **Pros:** Explicit, efficient, no codegen required.
*   **Cons:** Boilerplate.
    *   Need to define `Atom<T>` manually.
    *   Need to use `.watch()` or `Watch` widget explicitly.
    *   `NanoView` setup is verbose.

### 3. PoC Nano (Generated)
*   **Pros:**
    *   **Logic:** Looks like plain Dart.
        ```dart
        @nano
        class Counter {
            @state int count = 0;
            void increment() => count++;
        }
        ```
    *   **UI:** "SwiftUI-style" implicit tracking.
        ```dart
        NanoObserved(builder: (_) {
            return Text('${logic.count}'); // Updates automatically!
        })
        ```
*   **Cons:**
    *   Requires `build_runner`.
    *   Requires `NanoObserved` wrapper (similar to `Observer` in MobX).

## The Future: Dart Macros

Dart Macros (Experimental) will eliminate both cons of the current PoC:

1.  **No `build_runner`:** Macros run in real-time during compilation.
2.  **No `NanoObserved` Wrapper:** A macro like `@NanoWidget` can intercept the `build` method of a standard `StatelessWidget` and inject the tracking scope automatically.

See [MACRO_PREVIEW.dart](./MACRO_PREVIEW.dart) for a code example of this future state.

## How to Run

Since this is a PoC with local package dependencies, ensure you have the environment set up.

1.  **Generate Code:**
    ```bash
    cd example/generator_poc/example_app
    flutter pub get
    dart run build_runner build
    ```
    *(Note: `poc_nano_counter.g.dart` is currently checked in for reference so you can run without generating immediately)*

2.  **Run App:**
    ```bash
    flutter run
    ```
